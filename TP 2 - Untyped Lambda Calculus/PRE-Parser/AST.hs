module AST where

data Term    = Abs Idents Term | NoAbs No_abs --deriving Show
data No_abs  = App Leftap Rightap | At Atom --deriving Show
data Leftap  = AtomL Leftap Atom  | Ats Atom --deriving Show
data Rightap = Nil | AbsR Idents Term --deriving Show
data Atom    = Var Ident | Atom_term Term --deriving Show

--cambios de la gramatica. la rec a izquierda y el rightap a nil. 

-- en realidad leftap deberia hacerlos NO_abs = L | L" "R | A

--el AT Atom no va a entrar jamás, porque lo toma como una leftap Ats

data Idents  = Vs Ident Idents | V Ident 

type Ident   = String 


instance Show Idents where
        show (V i) = show i
        show (Vs i is) = (show i)++" "++(show is)


instance Show Term where
        show (Abs i t) = "/" ++ (show i) ++ "." ++ "(" ++ (show t) ++")"
        show (NoAbs n) = "(" ++  show n ++")"

instance Show No_abs where
        show (App l Nil) =  "(" ++  (show l) ++")"   
        show (App l r ) = "(" ++  (show l) ++")   (" ++  (show r) ++")" 
        show (At atom) = "(" ++ (show atom) ++ ")"

instance Show Leftap where
        show (AtomL l a) = "(" ++  (show l) ++")   (" ++  (show a) ++")" 
        show (Ats a) = show a
instance Show Rightap where
        show (Nil) = ""
        show (AbsR i t) = "("++show (Abs i t)++ ")"
instance Show Atom where
        show (Var i) = show i
        show (Atom_term t) = "("++(show t) ++ ")"




