module AST where

data Declaration = Decl Ctype Declarator
data Ctype = CInt | CChar | CFloat 
data Declarator = Pointer_to  Declarator | D String Size
--data Direct_declarator = Decl String Size deriving Show
data Size = Nil | Arr Int Size 


instance Show Ctype where
        show CInt = "Int"
        show CChar = "Char"
        show CFloat = "Float"

instance Show Declarator where
        show (Pointer_to d) = "*"++(show d)
        show (D xs sz) = xs ++ (show sz)

instance Show Size where
        show Nil = ""
        show (Arr n sz) = "["++ show n ++ "]" ++ (show sz)

instance Show Declaration where
        show ( Decl t d) = (show t) ++ " " ++ (show d)


--int a[5][6][7] ;= (CInt, D "a" (Arr 5 (Arr 6 (Arr 7))) )
