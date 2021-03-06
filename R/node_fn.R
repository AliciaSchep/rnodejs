#' Create a function to call a wrapped node.js package
#' 
#' Use this function to create functions that call node.js module commands. The
#' returned function will take arguments in the form of \code{argument=value} that
#' are passed to the node module CLI as \code{--argument=value}.
#' 
#' The function will retrun a list comprised of \code{output} (0/1 for success/
#' failure), \code{stdout}, and \code{stderr} from the node command.
#' 
#' @param node_package the directory name of the node package
#' @param node_bin the 'bin' command of the node package.  Defaults to the package name
#' @param node_dir the directory where node packages are kept.  Defaults to
#'                 'node', which should be a directory under 'inst' when
#'                 creaing your own package.
#' @param node_cmd  Optional. Command argument following the node binary, e.g.,
#'                  "init" in "dat init".
#' @param r_package the package name which wraps the function.  Defaults to the
#'                  \link{parent.frame}, assuming that \code{node_fn} is
#'                  being used in a package.
#' @param return_list If \code{TRUE}, the new function will return a list of
#'                    the return value, stdout, and stderr from the call to the
#'                    node.js function.  If \code{FALSE}, the new function will
#'                    return the results of a \link{system2} call.
#' @param ...         Additional parameters to pass to \link{system2} if
#'                    \code{return_list=FALSE}
#'                    
#' @import jsonlite
#' @export 
node_fn = function(node_package, node_cmd="", node_bin = node_package,
                        r_package  = environmentName(parent.frame()),
                        node_dir = "node", return_list = TRUE, ...) {

  nodepath = system.file(node_dir, package=r_package)
  nodepackage_path = file.path(nodepath, node_package)
  if(!check_node_deps(node_package, r_package, node_dir)) {
    stop(paste0(r_package, "node dependencies not installed."))
  }
  package.json = file.path(nodepackage_path, "package.json")
  if(!file.exists(package.json)) {
    stop("Node package '", node_package, "' not found in R package '",
         r_package, "' under directory '", node_dir, "'.")
  }
  package.data = fromJSON(package.json)
  package_name = package.data$name
  bin = package.data$bin[[node_bin]]
  if(is.null(bin)) stop("Command '", bin,  "' not found in node package'",
                        node_package, "'.")
                               
  node_command = do.call(file.path, as.list(c(nodepackage_path,
                                              strsplit(bin, "/")[[1]])))
  fn = function(args=list()) {     
     textargs = paste(node_cmd, ifelse(length(args) > 0,
                       paste0("--", names(args), " ", args, collapse=" "),
                       ""))
     node_command = c(node_command, textargs)
     outfile = tempfile()
     errfile = tempfile()
     if(return_list) {
       out = system3(node(), node_command)
     } else {
       out = system2(node(), node_command, ...)
     }
     return(out)
      }
  
  return(fn)
  }


system3 = function(command, args=character(), ...) {
     outfile = tempfile()
     errfile = tempfile()
     output = system2(command, args, stdout=outfile, stderr=errfile, ...)
     return(list(output=output,
                 stdout = readChar(outfile, file.info(outfile)$size),
                 stderr = readChar(errfile, file.info(errfile)$size)))
}
