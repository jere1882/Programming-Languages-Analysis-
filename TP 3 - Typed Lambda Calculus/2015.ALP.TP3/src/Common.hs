module Common where

  -- Comandos interactivos o de archivos
  data Stmt i = Def String i           --  Declarar un nuevo identificador x, let x = t
              | Eval i                 --  Evaluar el término
    deriving (Show)
  
  instance Functor Stmt where
    fmap f (Def s i) = Def s (f i)
    fmap f (Eval i)  = Eval (f i)

  -- Tipos de los nombres
  data Name
     =  Global  String
     |  Quote   Int
    deriving (Show, Eq)

  -- Entornos
  type NameEnv v t = [(Name, (v, t))]

  -- Tipo de los tipos
  data Type = Base 
            | Fun Type Type
            | Unit
            | Pair Type Type
            | Nat
            deriving (Show, Eq)
  
  -- Términos con nombres
  data LamTerm  =  LVar String
                |  Abs String Type LamTerm
                |  App LamTerm LamTerm
                |  Let String LamTerm LamTerm
                |  Has LamTerm Type  -- 
                |  U 
                |  Pairl LamTerm LamTerm
                |  Fstl LamTerm
                |  Sndl LamTerm
                |  Zerol
                |  Sucl LamTerm
                |  Recl LamTerm LamTerm LamTerm
        deriving (Show, Eq)


  -- Términos localmente sin nombres
  data Term  = Bound Int
             | Free Name 
             | Term :@: Term
             | Lam Type Term
             | Hast Term Type --
             | UT
             | Pairt Term Term
             | Fstt  Term 
             | Sndt  Term
             | Zerot
             | Suct Term
             | Rect Term Term Term
         deriving (Show, Eq)

  -- Valores
  data Value = VLam Type Term 
             | VUnit 
             | VPair Value Value 
             | VNum Numv

  data Numv = VZero | VSuc Numv 

  -- Contextos del tipado
  type Context = [Type]
