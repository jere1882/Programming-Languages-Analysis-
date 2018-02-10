module Parse2 where

import Parsing
import Data.Char
import Control.Monad
import Control.Applicative hiding (many)
import AST



--EJERCICIO 2

expr   :: Parser Int
expr   = do t <- term
            do {char '+' ; e <- expr ; return (t+e)} <|> do { char '-' ; e <- expr ; return (t-e) } <|> return t 


term   :: Parser Int
term   = do f <- factor 
            do {char '*' ; t<- term ; return (t*f) } <|> do { char '/' ; t <- term ; return (div f t) } <|> return f

factor :: Parser Int
factor = nat <|> do {char '(' ; e <- expr ; char ')' ; return e} 


eval2 :: String -> Int
eval2 xs = fst (head (parse expr xs) ) 



--EJERCICIO 3

transformador :: Parser a -> Parser a
transformador p = p <|> do char '('
                           e <- p
                           char ')'
                           return e;



--Parsing> let p' = transformador nat
--Parsing> parse nat "(56)"
--[]
--Parsing> parse p' "(56)"
--[(56,"")]


