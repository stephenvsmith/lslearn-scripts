############ Data Generation ############

# This code was given by a colleague, and later reworked to drop its
# dependency on sparsebnUtils/discretecdAlgorithm (both archived by CRAN on
# 2024-04-12) in favor of bnlearn + igraph, which remain maintained. See
# "Graph Utilities" below for the replacement functions.

generate.data.grid <- function(data.grid = data.frame(network = "child",
                                                      data.type = "continuous",
                                                      n.dat = 10,
                                                      n.obs = 1000,
                                                      c.ratio = 0,
                                                      max.in.degree = Inf,
                                                      lb = 0.5,  # lower bound of coefficients
                                                      ub = 1,  # upper bound of coefficients
                                                      low = 0,  # lower bound of variances if continuous, of number of levels if discrete
                                                      high = 1,  # upper bound of variances if continuous, of number of levels if discrete
                                                      scale = TRUE,
                                                      stringsAsFactors = FALSE),
                               out.dir,
                               array_num,
                               path.start='~/',
                               verbose = TRUE,
                               var_list=NULL){

  ## initialize output directory
  dir.check(out.dir)
  if (verbose) cat('generate.data.grid: Writing data.grid to output directory \n')
  write.table(data.grid, paste0(out.dir, '/data.grid.txt'))  # write data grid in out.dir

  for (i in 1:nrow(data.grid)){

    data.row <- data.grid[i,, drop = FALSE]
    data.dir <- paste0(out.dir, '/', data.row$network,
                       '_',array_num)
    dir.check(data.dir)
    write.txt <- function(obj, txt, col.names = FALSE, row.names = FALSE){  # function to write obj to data.dir
      write.table(obj, paste0(data.dir, sprintf('/%s.txt', txt)),
                  col.names = col.names, row.names = row.names)
    }
    write.txt(data.row, 'data.row', col.names = TRUE, row.names = TRUE)  # write data row in data.dir
    if (verbose) cat(sprintf('generate.data.grid: Generating data for network %s \n', data.row$networks))

    networks <- trimws(strsplit(data.row$network, split = ',')[[1]])
    true <- bnlearn2edgeList(bn.net = networks,
                             c.ratio = data.row$c.ratio,
                             max.parents = data.row$max.in.degree,
                             seed = i,
                             verbose = verbose,
                             net.dir = rds_dir,
                             path.start=path.start,var_list=var_list)
    true_edgeList <- true$edgeList
    trueDAG <- edgelist_to_adjmat(true_edgeList)
    trueCPDAG <- pcalg::dag2cpdag(trueDAG)
    trueGroup <- true$group
    n.edge <- sum(lengths(true_edgeList))
    n.node <- length(true_edgeList)

    ## generate order matrix
    set.seed(i)
    order.mat <- replicate(data.row$n.dat, sample(1:n.node))

    ## write
    write.txt(trueDAG, 'trueDAG')
    write.txt(trueCPDAG, 'trueCPDAG')
    write.txt(trueGroup, 'trueGroup')
    write.txt(order.mat, 'order.mat')

    ## generate data
    set.seed(i)
    if (data.row$data.type == 'continuous'){

      params.mat <- replicate(data.row$n.dat, {
        coefs <- runif(n.edge, min = data.row$lb, max = data.row$ub) * sample(c(-1, 1), n.edge, replace = TRUE)  # sample correlation from Unif([-ub, -lb] U [lb, ub])
        vars <- runif(n.node, min = data.row$low, max = data.row$high)  # sample noise variance
        params <- c(coefs, vars)  # parameter format for generating data
        return(params)
      })
      write.txt(params.mat, 'params.mat')

      for (j in 1:data.row$n.dat){
        if(verbose) cat(sprintf('generate.data.grid: Generating dataset %s \n', j))
        set.seed(j)

        vars <- utils::tail(params.mat[,j], n.node)  # extract variances
        noise.matrix <- sapply(vars, function(x){rnorm(data.row$n.obs, 0, sqrt(x))})
        dat <- generate_dat(true_edgeList, params.mat[,j], noise.matrix, data.row$n.obs, if_scale = data.row$scale)
        write.txt(dat, paste0('data', j))
      }  # end for
    } else if (data.row$data.type == 'discrete'){
      # Discrete data generation previously used discretecdAlgorithm::coef_gen()
      # and ::generate_discrete_data(), but that package (and its hard
      # dependency, sparsebnUtils) was archived by CRAN on 2024-04-12 and is
      # no longer installable. This branch was never exercised for this
      # paper's published results (the simulation study is entirely
      # continuous/Gaussian; see run/arraykernel.R), so it hasn't been
      # reimplemented -- doing so natively (CPT generation + ancestral
      # sampling for a discrete DAG) is a separate, self-contained piece of
      # work deserving its own testing. See README.md's "Compatibility with
      # lslearn" section.
      stop(paste(
        'generate.data.grid: discrete data generation is not currently',
        'implemented (discretecdAlgorithm was archived by CRAN; see the',
        'comment above this stop() in R/data_gen.R).'
      ))
    }  # end discrete
  }
}


#	Function: bn.repository
#
#	Description:
#
#		Loads a bnlearn Bayesian network repository.
#
#	Arguments:
#
#		bn.net - Name of network from bnlearn Bayesian network repository.
#   net.dir - Bayesian network directory containing folder rds containing bnlearn networks stored as network.rds files.
#
#	Returns:
#
#		out - Parent edge weight list. Each named element contains parents, indices, and weights.

bn.repository <- function(bn.net,  # character scalar of
                          path.start='~/',
                          net.dir = NULL){  # directory of bn.net .rda files
  if (is.null(net.dir)){
    net.dir <- paste0(path.start,"networks")
  }
  bn <- readRDS(sprintf(paste0(net.dir, "/%s.rds"), tolower(bn.net)))

  return(bn)
}


#	Function: edgelist_to_adjmat / adjmat_to_edgelist / edgelist_to_weighted
#
#	Description:
#
#		Replacements for the sparsebnUtils functionality this file used to
#		depend on (get.adjacency.matrix, to_edgeList, as.sparse). An
#		"edgeList" throughout this file is simply a plain list of length p
#		(one element per node), where element `child` is an integer vector
#		of `child`'s parent node indices -- exactly the list sparsebnUtils'
#		own edgeList() constructor wrapped in an S3 class; no class is
#		needed here since these functions operate on the plain list
#		directly instead of dispatching on it.
#
#	Arguments:
#
#		edgelist - A plain edgeList as described above.
#		adjmat   - A p x p 0/1 adjacency matrix, adjmat[parent, child] == 1.
#		coefs    - A flat numeric vector of edge coefficients, one per edge,
#		           ordered by iterating child 1..p and, within each child,
#		           its parents in the order stored in edgelist[[child]].
#		           (Consumers only need to agree with generate.data.grid()'s
#		           own draw order, which uses this same convention, not with
#		           any external package's edge ordering.)
#		node_name - Character vector of node names.
#
#	Returns:
#
#		edgelist_to_adjmat   - the p x p 0/1 adjacency matrix.
#		adjmat_to_edgelist   - a plain edgeList (see above).
#		edgelist_to_weighted - a named list, one element per node, each a
#		                       list(parents, index, weights) for that node's
#		                       incoming edges.

edgelist_to_adjmat <- function(edgelist){
  p <- length(edgelist)
  adj <- matrix(0, nrow = p, ncol = p)
  for (child in seq_len(p)){
    parents <- edgelist[[child]]
    if (length(parents) > 0) adj[parents, child] <- 1
  }
  if (!is.null(names(edgelist))) dimnames(adj) <- list(names(edgelist), names(edgelist))
  adj
}

adjmat_to_edgelist <- function(adjmat){
  p <- ncol(adjmat)
  out <- lapply(seq_len(p), function(child) which(adjmat[, child] == 1))
  if (!is.null(colnames(adjmat))) names(out) <- colnames(adjmat)
  out
}

edgelist_to_weighted <- function(edgelist, coefs, node_name){
  p <- length(edgelist)
  out <- vector("list", p)
  names(out) <- node_name
  pos <- 1
  for (child in seq_len(p)){
    parents <- edgelist[[child]]
    n_parent <- length(parents)
    if (n_parent > 0){
      weights <- coefs[pos:(pos + n_parent - 1)]
      pos <- pos + n_parent
      out[[child]] <- list(parents = node_name[parents], index = parents, weights = weights)
    } else {
      out[[child]] <- list(parents = character(0), index = integer(0), weights = numeric(0))
    }
  }
  out
}


#	Function: bnlearn2edgeList
#
#	Description:
#
#		Creates a plain edgeList (see "Graph Utilities" above), by connecting networks if desired, from the bnlearn Bayesian network repository.
#
#	Arguments:
#
#		bn.net - Character object with name(s) of networks in bnlearn repository. Repeat network name k times for k identically structured subgraphs.
#   c.ratio - Connectivity ratio constant c. Subgraphs are connected with (c * total edges within subgraphs) edges.
#   max.parents - Maximum number of parents per node (maximum in-degree). If a node has max.parents or more parents, an edge to the node will not be considered.
#   net.dir - Bayesian network directory containing folder rds containing bnlearn networks stored as network.rds files.
#   seed - Random seed.
#
#	Returns:
#
#		List containing:
#
#       edgeList - Fused plain edgeList (see "Graph Utilities" above).
#       group - True group of each node.
#       n.edges - Numeric vector containing number of edges within subgraphs (s_w) and number of edges between subgraphs (s_b).
#       n.parents - Number of parents for each node.
#       seed - Random seed argument.
#
#	Examples:
#
#   > pigs <- bnlearn2edgeList(bn.net = "pigs")
#   > edgelist_to_adjmat(pigs$edgeList)
#		> mix <- bnlearn2edgeList(bn.net = c("pigs", "pathfinder", "hailfinder"),
#                            c.ratio = 0.1)
#   > edgelist_to_adjmat(mix$edgeList)

bnlearn2edgeList <- function(bn.net,
                             c.ratio = 0,
                             max.parents = Inf,
                             net.dir = NULL,
                             seed = NULL,
                             verbose = FALSE,
                             path.start='~/',
                             var_list=NULL){

  if (is.null(seed)){
    seed <- 1
  }
  set.seed(seed)

  if (!is.null(var_list)) net.dir <- var_list$rds_dir

  bn.net.list <- lapply(bn.net, function(x){
    bn <- readRDS(sprintf(paste0(net.dir, "/%s.rds"), tolower(x)))
    lapply(bn, function(x) match(x$parents, names(bn)))  # plain edgeList (see "Graph Utilities")
  })

  n.net <- length(bn.net)
  net.len <- sapply(bn.net.list, length)
  net.edgeList <- do.call("c",
                          lapply(1:n.net, function(x)
                            lapply(bn.net.list[[x]], function(y)
                              y + sum(net.len[1:x]) - net.len[x]))
  )  # end do.call
  names(net.edgeList) <- paste0("V", 1:length(net.edgeList))

  ## add random edges between
  if(n.net > 1 &&  # no c if only 1 network
     c.ratio){
    n.btwn <- ceiling(c.ratio * length(unlist(net.edgeList)))  # pick c * k * s_sub edges
    cum.net.len <- c(0, cumsum(net.len))

    if (verbose) cat(sprintf('bnlearn2edgeList: Connecting subgraphs with %s edges \n', n.btwn))
    continue <- TRUE

    ## repeat until success
    while (continue){

      ## regenerate edge list
      net.edgeList <- do.call(c,
                              lapply(1:n.net, function(x)
                                lapply(bn.net.list[[x]], function(y)
                                  y + sum(net.len[1:x]) - net.len[x]))
      )  # end do.call
      names(net.edgeList) <- paste0("V", 1:length(net.edgeList))
      net.adjMat <- edgelist_to_adjmat(net.edgeList)  # store as adjacency matrix
      valid.child <- which(colSums(net.adjMat) < max.parents)  # valid children to search have fewer than maximum parents

      ## generate all possible edges between
      btwn.edges <- do.call(rbind, lapply(1:n.net, function(x){  # all possible combinations
        expand.grid(cum.net.len[x] + 1:net.len[x],  # from group x
                    setdiff(1:length(net.edgeList), cum.net.len[x] + 1:net.len[x]))  # to a different group
      }))  # includes both directions
      btwn.edges <- btwn.edges[btwn.edges[,2] %in% valid.child,]  # choose all rows that have child that is valid
      btwn.edges <- btwn.edges[sample(1:nrow(btwn.edges)),]  # reorder btwn edges to be chosen in random order

      ## add edges one at a time
      for (i in 1:nrow(btwn.edges)){  # for each candidate
        net.adjMat[btwn.edges[i,1], btwn.edges[i,2]] <- 1  # parents in rows, child in column

        if (! gRbase::is.DAG(net.adjMat) |  # if not a DAG
            sum(net.adjMat[, btwn.edges[i,2]]) > max.parents){  # or if child has too many parents
          net.adjMat[btwn.edges[i,1], btwn.edges[i,2]] <- 0  # remove edge
          if (i == nrow(btwn.edges)){  # if not a DAG and exhausted candidates
            cat(sprintf('bnlearn2edgeList: Failed attempt with %s edges added \n', sum(net.adjMat) - length(unlist(net.edgeList))))
          }
        } else if (sum(net.adjMat) == (length(unlist(net.edgeList)) + n.btwn)){  # if is DAG and all edges acquired
          if (verbose) cat('bnlearn2edgeList: Successfully connected subgraphs \n')
          continue <- FALSE
          break  # no longer search through edges
        }

        if (verbose > 1 && (i %% 100) == 0){
          cat(sprintf('bnlearn2edgeList: Successfully added %s edges \n', i))
        }
      }
      net.edgeList <- adjmat_to_edgelist(net.adjMat)
    }  # end while
  } else n.btwn <- 0

  # groups
  group <- rep(1:n.net, net.len)

  # get number of original levels for each node
  bn.list <- lapply(bn.net, function(x){
    bn <- readRDS(sprintf(paste0(net.dir, "/%s.rds"), tolower(x)))
    return(bn)
  })
  n.levels <- unlist(lapply(bn.list, function(x){
    sapply(x, function(y){
      dim(y$prob)[1]
    })
  }))

  # get number of parents per node
  n.parents <- sapply(net.edgeList, length)

  out <- list(edgeList = net.edgeList,
              group = group,
              n.edges = c(s_w = length(unlist(net.edgeList)) - n.btwn, s_b = n.btwn),
              n.levels = n.levels,
              n.parents = n.parents,
              seed = seed)

  return(out)
}


#	Function: generate_dat
#
#	Description:
#
#		Generates data.
#
#	Arguments:
#
#		true_edgeList - True parent edge list.
#   params - Parameters containing coefficients for each edge and noise variance of each variable.
#   noise_matrix - Pre-generated noise matrix using the noise variance of each variable in params.
#   n_obs - Number of observations to generate.
#   if_scale - Logical value indicating whether or not to scale each column to have variance = 1 in the generating process.
#
#	Returns:
#
#		data_matrix - Generated data matrix.

generate_dat <- function(true_edgeList, params, noise_matrix, n_obs, if_scale = FALSE) {
  node_name <- names(true_edgeList)
  n_node <- length(true_edgeList)

  # Topological order. Vertex indices from graph_from_adjacency_matrix()
  # correspond directly to true_edgeList's own 1..n_node indexing (no name
  # matching needed, unlike the old sparsebnUtils::to_igraph() round-trip).
  adjmat <- edgelist_to_adjmat(true_edgeList)
  true_graph <- igraph::graph_from_adjacency_matrix(adjmat, mode = "directed")
  ts <- as.integer(igraph::topo_sort(true_graph))

  vars <- utils::tail(params, n_node) # parameters associated with variances
  names(vars) <- node_name
  coefs <- params[1:(length(params) - n_node)] # parameters associated with edge weights
  edgelist <- edgelist_to_weighted(true_edgeList, coefs, node_name)

  data_matrix <- matrix(0, nrow = n_obs, ncol = n_node)
  for(i in 1:n_node) {
    child <- ts[i]
    parent <- true_edgeList[[child]]
    n_parent <- length(parent)
    if (n_parent) {
      beta <- matrix(edgelist[[child]]$weights, ncol = 1)
      new_data <- data_matrix[, parent, drop = FALSE] %*% beta + noise_matrix[, child, drop = FALSE]
    } else {
      new_data <- noise_matrix[, child, drop = FALSE]
    }
    if (if_scale == TRUE) {
      new_data <- scale(new_data)
    }
    data_matrix[, child] <- new_data
  }
  return(data_matrix)
}


#	Function: dir.check
#
#	Description:
#
#		Checks if a directory exists, creating the directory if necessary.
#
#	Arguments:
#
#		dir - Character working directory.
#   min.depth - Minimum depth. If folders earlier than min.depth do not exist (likely because of typos), stop.
#
#	Returns:
#
#		None. Creates missing working directory.

dir.check <- function(dir, min.depth = 0){

  folders <- strsplit(dir, split = '/')[[1]]
  folders <- folders[folders != '']  # end(s)

  stopifnot(length(folders) >= min.depth)  # stop if not enough folders

  for (i in 1:length(folders)){

    temp.dir <- paste0(c('', folders[1:i]), collapse = '/')
    if (i < min.depth){  # below minimum depth
      stopifnot(dir.exists(temp.dir))  # if directory does not exist, stop
    } else if (!dir.exists(temp.dir)) {  # if at least minimum depth and doesn't exist
      cat(sprintf('dir.check: Creating folder `%s`\n', folders[i]) )
      dir.create(file.path(temp.dir))  # create directory
    }
  }
}
