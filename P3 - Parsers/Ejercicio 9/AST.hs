module AST where

type Declaracion = (Tipo, Declarador) 
data Tipo = CInt | CChar | CFloat deriving Show 
data Declarador = D Declarador_directo2 | Puntero_a Declarador deriving Show
--data Declarador_directo = Ident String | Arr Declarador_directo Size deriving Show
type Size = Int


data Declarador_directo2 = Decl String Algo deriving Show
data Algo = Fin | Sz Algo Size   deriving Show


-- a [4][5][6] = Arr "a" (Sz (Sz (Sz Fin 4) 5) 6) este caso lo agarra al reves
