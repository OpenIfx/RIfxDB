# Hello, world!
#
# This is an example function named 'hello' 
# which prints 'Hello, world!'.
#
# You can learn more about package authoring with RStudio at:
#
#   http://r-pkgs.had.co.nz/
#
# Some useful keyboard shortcuts for package authoring:
#
#   Build and Reload Package:  'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'

# library(RIfxDB)
#
.onLoad <- function(lib, package) 
{
   library.dynam("RIfxDB", package, lib )
}

hello <- function() 
{
  print("Hello, world!")
}


Increment <- function(x) 
{
  # .Call( "Increment" )
  # .Call( getNativeSymbolInfo("Increment") )
  .Call( Ifx_Increment, x )
}


Multiply <- function(x, y) 
{
  # .C() automatically converts back and forth between R vectors and their C equivalents.
  # The output will be on the third parameter, extract that
  .C( Ifx_Multiply, x, y, numeric(1) ) [[3]]
}


Divide <- function(x, y) 
{
  # .C() automatically converts back and forth between R vectors and their C equivalents.
  # The output will be on the third parameter, extract that
  .C( Ifx_Divide,  x, y, numeric(1) ) [[3]]
}


MyPi <- function() 
{
  .Call(Ifx_MyPi)
}


Add <- function(x, y) 
{
  .Call(Ifx_Add, x, y)
}


Subtract <- function(x, y) 
{
  .Call(Ifx_Subtract, x, y)
}


