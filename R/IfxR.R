# file IfxR/R/IfxR.R
# copyright 2017  Sathyanesh Krishnan
# copyright 2017  Javier Sagrera
#
#########################################################################
# copyright (C) 1999-2002  M. Lapsley
# copyright (C) 2002-2016  B. D. Ripley
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 or 3 of the License
#  (at your option).
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.r-project.org/Licenses/
#
#
#
#
.onLoad <- function(libname, pkgname)
{

     if(is.null(getOption("dec")))
          options(dec = Sys.localeconv()["decimal_point"])
    #library.dynam("IfxR", package, lib )
        
}

.onUnload <- function(libpath)
{
    IfxCloseAll()
    .Call(C_IfxRTerm)
    library.dynam.unload("IfxR", libpath)
}

IfxGetErrMsg <- function(channel)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    err <- .Call(C_IfxRGetErrMsg, attr(channel, "handle_ptr"))
    .Call(C_IfxRClearError, attr(channel, "handle_ptr"))
    return(err)
}

IfxClearError <- function(channel)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    .Call(C_IfxRClearError, attr(channel, "handle_ptr"))
    invisible()
}

IfxReConnect <- function(channel, ...)
{
    if(!inherits(channel, "IfxR"))
        stop("Argument 'channel' must inherit from class IfxR")
    Call <- attr(channel, "call")
    dots <- list(...)
    if("uid" %in% names(dots)) {
        uid <- dots$uid; dots$uid <- NULL
        Call$Connection <- sub("UID=[^;]+($|;)",
                               paste("UID=", uid, ";", sep=""),
                               Call$connection)
    }
    if("pwd" %in% names(dots)) {
        pwd <- dots$pwd; dots$pwd <- NULL
        Call$connection <- sub("PWD=[^;]+($|;)",
                               paste("PWD=", pwd, ";", sep=""),
                               Call$connection)
    }
    if(length(dots)) Call[names(dots)] <- dots
    eval.parent(Call)
}

IfxConnect <- function (ConnStr, uid = "", pwd = "", ...)
{
    Call <- match.call(); Call$uid <- Call$pwd <- NULL
    Call[[1]] <- quote(IfxR::IfxDriverConnect)

    # st <- paste( ConnStr, sep="")
    st <- ConnStr

    if(nchar(uid)) st <- paste(st, ";UID=", uid, sep="")
    if(nchar(pwd)) st <- paste(st, ";PWD=", pwd, sep="")
    Call[[2]] <- st; names(Call)[2] <- ""
    eval.parent(Call)
}

IfxDriverConnect <-
    function (connection = "", case = "nochange", believeNRows = TRUE,
              colQuote, tabQuote = colQuote, interpretDot = TRUE,
              DBMSencoding = "", rows_at_time = 100, readOnlyOptimize = FALSE)
{
   id <- as.integer(1 + runif(1, 0, 1e5))

   stat <- .Call(C_IfxRDriverConnect, as.character(connection), id,
                 as.integer(believeNRows), as.logical(readOnlyOptimize))
   if(stat < 0L) {
       warning("IfxR connection failed")
       return(stat)
   }

   Call <- match.call()
   res <- .Call(C_IfxRGetInfo, attr(stat, "handle_ptr"))
   isMySQL <- res[1L] == "MySQL"
   if(missing(colQuote)) colQuote <- ifelse(isMySQL, "`", '"')
   if(missing(case))
       case <- switch(res[1L],
                      "MySQL" = "mysql",
                      "PostgreSQL" = "postgresql",
                      "nochange")
   switch(case,
	toupper = case <- 1L,
	tolower = case <- 2L,
	postgresql = case <- 2L,
	nochange = case <- 0L,
	msaccess = case <- 0L,
	mysql = case <- ifelse(.Platform$OS.type == "windows", 2L, 0L),
 	stop("Invalid case parameter: nochange | toupper | tolower | common db names")
	)
   case <- switch(case+1L, "nochange", "toupper", "tolower")
   rows_at_time <- max(1, min(1024, rows_at_time))
   cs <- attr(stat, "connection.string")
   if(grepl("PWD=", cs)) {
       attr(stat, "connection.string") <- sub("PWD=[^;]+($|;)", "PWD=******;", cs)
       Call$connection <- sub("PWD=[^;]+($|;)", "PWD=******;", connection)
   }
   structure(stat, class = "IfxR", case = case, id = id,
             believeNRows = believeNRows,
             colQuote = colQuote, tabQuote = tabQuote,
             interpretDot = interpretDot,
             encoding = DBMSencoding,
             rows_at_time = rows_at_time, isMySQL = isMySQL,
             call = Call)
}

IfxQuery <-
    function(channel, query, rows_at_time = attr(channel, "rows_at_time"))
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    if(nchar(enc <- attr(channel, "encoding"))) query <- iconv(query, to=enc)
    .Call(C_IfxRQuery, attr(channel, "handle_ptr"), as.character(query),
          as.integer(rows_at_time))
}

IfxUpdate <-
    function(channel, query, data, params, test = FALSE, verbose = FALSE,
             nastring = NULL)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    ## sanity checks!
    if(length(params) == 0L || nrow(params) == 0L)
        stop("no parameters, so nothing to update")
    if(nchar(enc <- attr(channel, "encoding"))) query <- iconv(query, to=enc)
    vflag <- 0
    if(verbose) vflag <- 1
    if(test) vflag <- 2
    ## apply the name mangling that was applied when the table was created
    cnames <- mangleColNames(names(data))
    cnames <- switch(attr(channel, "case"),
                     nochange = cnames,
                     toupper = toupper(cnames),
                     tolower = tolower(cnames))
    for(i in seq_along(data))
        if(!is.numeric(data[[i]])) {
            data[[i]] <- as.character(data[[i]])
            if(nchar(enc)) data[[i]] <- iconv(data[[i]], to = enc)
        }
    ## now map names: ds[i] is the data col to go with param i.
    ds <- match(params[[1]], cnames)
    if(any(is.na(ds))) stop("missing columns in 'data'")
    ## but pass 0-indexed version of ds
    .Call(C_IfxRUpdate, attr(channel, "handle_ptr"), as.character(query),
          data, ds-1L, params, as.integer(vflag))
}

## catalog, schema, tableName are 'pattern-value's
## IBM says % is special, and asks for all schemas or tableTypes to be listed.
## MSDN says there are values SQL_ALL_CATALOGS, SQL_ALL_SCHEMAS,
## SQL_ALL_TABLE_TYPES, but the headers define these as "%".
## tableType is a character vector containing one of more of
## "TABLE" "VIEW" "SYSTEM TABLE" "ALIAS" "SYNONYM" (may be single-quoted).
## http://publib.boulder.ibm.com/infocenter/dzichelp/v2r2/index.jsp?topic=/com.ibm.db29.doc.odbc/db2z_fntables.htm
IfxTables <- function(channel, catalog = NULL, schema = NULL,
                        tableName = NULL, tableType = NULL, literal = FALSE)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    tableType  <- if(is.character(tableType) && length(tableType))
        paste(tableType, collapse=",") else NULL
    .Call(C_IfxRTables, attr(channel, "handle_ptr"),
          catalog, schema, tableName, tableType, as.logical(literal))
}

IfxColumns <- function(channel, table, catalog = NULL, schema = NULL,
                        literal = FALSE)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    .Call(C_IfxRColumns, attr(channel, "handle_ptr"),
          as.character(table), catalog, schema, as.logical(literal))
}

IfxSpecialColumns <- function(channel, table, catalog = NULL, schema = NULL)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    .Call(C_IfxRSpecialColumns, attr(channel, "handle_ptr"),
          as.character(table), catalog, schema)
}

IfxPrimaryKeys <- function(channel, table, catalog = NULL, schema = NULL)
{
    if(!IfxValidChannel(channel))
        stop("first argument is not an open IfxR channel")
    .Call(C_IfxRPrimaryKeys, attr(channel, "handle_ptr"),
          as.character(table), catalog, schema)
}

close.IfxR <- function(con, ...) invisible(ifelse(IfxClose(con), 0L, 1L))

IfxClose <- function(channel)
{
    if(!IfxValidChannel(channel))
       stop("argument is not an open IfxR channel")
    res <- .Call(C_IfxRClose, attr(channel, "handle_ptr"))
    if(res > 0) invisible(FALSE) else {
        warning(paste(IfxGetErrMsg(channel), sep="\n"))
        FALSE
    }
    invisible(TRUE)
}

IfxCloseAll <- function()
{
    .Call(C_IfxRCloseAll)
    invisible()
}

IfxFetchRows <-
    function(channel, max = 0, buffsize = 1000,
             nullstring = NA_character_, believeNRows = TRUE)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    .Call(C_IfxRFetchRows, attr(channel, "handle_ptr"), max, buffsize,
          as.character(nullstring), believeNRows)
}

IfxCaseFlag <- function (channel)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    attr(channel, "case")
}

IfxGetInfo <- function(channel)
{
    if(!IfxValidChannel(channel))
       stop("argument is not an open IfxR channel")
    res <- .Call(C_IfxRGetInfo, attr(channel, "handle_ptr"))
    names(res) <- c("DBMS_Name", "DBMS_Ver", "Driver_ODBC_Ver",
                    "Data_Source_Name", "Driver_Name", "Driver_Ver",
                    "ODBC_Ver", "Server_Name")
    res
}

IfxValidChannel <- function(channel)
{
    inherits(channel, "IfxR") && is.integer(channel) &&
    .Call(C_IfxRcheckchannel, channel, attr(channel, "id")) > 0
}

IfxClearResults <-  function(channel)
{
    if(!IfxValidChannel(channel))
       stop("first argument is not an open IfxR channel")
    .Call(C_IfxRclearresults, attr(channel, "handle_ptr"))
    invisible()
}

print.IfxR <- function(x, ...)
{
    con <- strsplit(attr(x, "connection.string"), ";", fixed = TRUE)[[1L]]
    case <- paste("case=", attr(x, "case"), sep="")
    cat("IfxR Connection ", as.vector(x), "\nDetails:\n  ", sep = "")
    cat(case, con, sep="\n  ")
    invisible(x)
}

IfxSetAutoCommit <- function(channel, autoCommit = TRUE)
{
    if(!IfxValidChannel(channel))
         stop("first argument is not an open IfxR channel")
    .Call(C_IfxRSetAutoCommit, attr(channel, "handle_ptr"), autoCommit)
}

IfxEndTran <- function(channel, commit = TRUE)
{
    if(!IfxValidChannel(channel))
         stop("first argument is not an open IfxR channel")
    .Call(C_IfxREndTran, attr(channel, "handle_ptr"), commit)
}

IfxDataSources <- function(type = c("all", "user", "system"))
{
    type <- match.arg(type)
    type <- match(type, c("all", "user", "system"))
    .Call(C_IfxRListDataSources, type)
}

MyPi <- function() 
{
  .Call(C_MyPi)
}

