module Eval2 (eval) where
-- Utilizaremos Either para diferenciar expresiones erroneas de expresiones correctas.
import AST

-- Estados
type State = [(Variable,Int)]
type Error = String

-- Estado nulo
initState :: State
initState = []

-- Busca el valor de una variable en un estado
-- Completar la definicion
lookfor :: Variable -> State -> Int
lookfor v s = [ b | (a,b) <- s, a==v] !! 0

-- Cambia el valor de una variable en un estado
-- Completar la definicion
update :: Variable -> Int -> State -> State
update v n s = [ (a,b) | (a,b) <- s , a/=v ] ++ [ (v,n) ]
 
-- isError v devuelve True si v es un error, y sino devuelve False
isError :: Either a b -> Bool
isError (Right _) = True
isError (Left _ ) = False

-- f v devuelve el valor de v, sacando el constructor Left. No esta definido para Right (los Right siempre son errores)
f :: Either a b -> a
f (Left n) = n

-- Evalua un programa en el estado nulo
eval :: Comm -> Either State Error
eval p = evalComm p initState

-- El procedimiento es siempre el mismo, tanto para evalComm como para evalIntExp y evalBoolExp: analizar si cualquier subexpresion es un error. En el caso de serlo, devolvemos  Right "error", caso contrario procedemos como en Eval1.hs con el constructor Left 
-- Para ello utilizamos la funcion isError y f.
evalComm :: Comm -> State -> Either State Error
evalComm Skip s = Left s
evalComm (Let v n) s | isError value    = Right "error"
                     | otherwise        = Left (update v (f value) s)
                        where value = evalIntExp n s

evalComm (Seq c1 c2) s | isError value1 || isError value2 = Right "error"
                       | otherwise                        = value2 
        where value1 = evalComm c1 s
              value2 = evalComm c2 (f value1)

evalComm (Cond b ct cf) s | isError cond        = Right "error"
                          | cond == (Left True) = evalComm ct s 
                          | otherwise           = evalComm cf s 
        where cond = evalBoolExp b s

evalComm w@(While b c) s | isError cond        = Right "error"
                         | cond == (Left True) = evalComm (Seq c w) s
                         | otherwise           = Left s

        where cond = evalBoolExp b s

-- Chequeamos, ademas, el caso de la division por 0.

evalIntExp :: IntExp -> State -> Either Int Error
evalIntExp (Const x) s = Left x
evalIntExp (Var v) s = Left (lookfor v s) 
evalIntExp (UMinus e) s | isError value     =  Right "error"
                        | otherwise         = Left (  (-1) * (f value)  )
                         where value = evalIntExp e s
                        
evalIntExp (Plus e1 e2) s | (isError value1) || (isError value2) = Right "error" 
		          | otherwise                            = Left ( f value1 + f value2)
			 where (value1,value2) = (evalIntExp e1 s,evalIntExp e2 s)

evalIntExp (Minus e1 e2) s   | (isError value1) || (isError value2) = Right "error" 
			     | otherwise                            = Left ( f value1 - f value2)
	                 where (value1,value2) = (evalIntExp e1 s,evalIntExp e2 s)

evalIntExp (Times e1 e2) s  | (isError value1) || (isError value2) = Right "error" 
			    | otherwise                            = Left ( f value1 * f value2)
			 where (value1,value2) = (evalIntExp e1 s,evalIntExp e2 s)

evalIntExp (Div e1 e2) s   | (isError value1) || (isError value2) = Right "error" 
                           | f value2 == 0                        = Right "error"
			   | otherwise                            = Left ( div (f value1) (f value2) )
			 where (value1,value2) = (evalIntExp e1 s,evalIntExp e2 s)


evalBoolExp :: BoolExp -> State -> Either Bool Error

evalBoolExp BTrue s = Left True
evalBoolExp BFalse s = Left False
evalBoolExp (Eq e1 e2) s | isError exp1 || isError exp2 = Right "error"
                         | otherwise                    = Left ( f exp1 == f exp2 )
        where (exp1,exp2) = (evalIntExp e1 s, evalIntExp e2 s)

evalBoolExp (Lt e1 e2) s | isError exp1 || isError exp2 = Right "error"
                         | otherwise                    = Left ( f exp1 < f exp2 )
        where (exp1,exp2) = (evalIntExp e1 s, evalIntExp e2 s)

evalBoolExp (Gt e1 e2) s | isError exp1 || isError exp2 = Right "error"
                         | otherwise                    = Left ( f exp1 > f exp2 )
        where (exp1,exp2) = (evalIntExp e1 s, evalIntExp e2 s)


evalBoolExp (And b1 b2 ) s | isError exp1 || isError exp2 = Right "error"
                           | otherwise                    = Left ( f exp1 && f exp2 )
        where (exp1,exp2) = (evalBoolExp b1 s, evalBoolExp b2 s)

evalBoolExp (Or b1 b2 ) s | isError exp1 || isError exp2 = Right "error"
                          | otherwise                    = Left ( f exp1 || f exp2 )
        where (exp1,exp2) = (evalBoolExp b1 s, evalBoolExp b2 s)

evalBoolExp (Not b) s | isError exp = Right "error"
                      | otherwise   = Left (not (f exp))
        where exp = evalBoolExp b s


