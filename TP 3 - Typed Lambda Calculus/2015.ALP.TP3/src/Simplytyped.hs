module Simplytyped (
       conversion,    -- conversion a terminos localmente sin nombre
       eval,          -- evaluador
       infer,         -- inferidor de tipos
       quote          -- valores -> terminos
       )
       where

import Data.List
import Data.Maybe
import Prelude hiding ((>>=))
import Text.PrettyPrint.HughesPJ (render)
import PrettyPrinter
import Common

-- conversion a términos localmente sin nombres
conversion :: LamTerm -> Term
conversion = conversion' []
conversion' :: [String] -> LamTerm -> Term
conversion' b (LVar n)        = maybe (Free (Global n)) Bound (n `elemIndex` b)
conversion' b (App t u)       = conversion' b t :@: conversion' b u
conversion' b (Abs n t u)     = Lam t (conversion' (n:b) u)
conversion' b (Let x t1 t2)   = conversion' b (App  (Abs x t t2) t1 )
        where t = der (infer [] (conversion' b t1) )
              der (Right r) = r
              der _         = error "(Conversion-let) error en un let cuando infiero el tipo"
conversion' b (Has e t)       = Hast (conversion' b e) t
conversion' b U               = UT 
conversion' b (Pairl l r)     = Pairt (conversion' b l) (conversion' b r)
conversion' b (Fstl e)        = Fstt (conversion' b e)
conversion' b (Sndl e)        = Sndt (conversion' b e)
conversion' b (Zerol)         = Zerot
conversion' b (Sucl e)        = Suct (conversion' b e)
conversion' b (Recl e1 e2 e3) = Rect (conversion' b e1) (conversion' b e2) (conversion' b e3)
-----------------------
--- eval
-----------------------

sub :: Int -> Term -> Term -> Term
--Sustituye en el 3er término por el 2do término.

sub i t (Bound j) | i == j    = t
sub _ _ (Bound j) | otherwise = Bound j
sub _ _ (Free n)              = Free n
sub i t (u :@: v)             = sub i t u :@: sub i t v
sub i t (Lam t' u)            = Lam t' (sub (i+1) t u)
sub i t (Hast e t')           = Hast (sub i t e) t'
sub i t UT                    = UT 
sub i t (Pairt l r)           = Pairt (sub i t l) (sub i t r)
sub i t (Fstt e)              = Fstt (sub i t e)
sub i t (Sndt e)              = Sndt (sub i t e)
sub i t Zerot                 = Zerot
sub i t (Suct e)              = Suct (sub i t e)
sub i t (Rect e1 e2 e3)       = Rect (sub i t e1) (sub i t e2) (sub i t e3)

-- evaluador de términos
eval :: NameEnv Value Type -> Term -> Value
eval _ (Bound _)             = error "variable ligada inesperada en eval"
eval e (Free n)              = fst $ fromJust $ lookup n e
eval _ (Lam t u)             = VLam t u
eval e (Lam _ u :@: Lam s v) = eval e (sub 0 (Lam s v) u)
eval e (Lam t u :@: v)       = case eval e v of --hacemos case sobre un valor, hay q poner todo los valores
                 VLam t' u' -> eval e (Lam t u :@: Lam t' u')
                 VUnit      -> eval e (sub 0 UT u)
                 VNum v     -> eval e (sub 0 (quote (VNum v)) u)
                 _          -> error "Error de tipo en run-time, verificar type checker"
eval e (u :@: v)             = case eval e u of
                 VLam t u' -> eval e (Lam t u' :@: v)
                 VUnit     -> error "(eval-abs) A la izquierda hay un VUnit"
                 VNum v    -> error "(eval-abs) A la izquierda hay un VNum "
                 _         -> error "Error de tipo en run-time, verificar type checker"

eval e (Hast exp t)          = eval e exp
eval e UT                    = VUnit
eval e (Pairt l r)           = VPair v1 v2
        where (v1,v2) = (eval e l, eval e r)

eval e (Fstt exp)            = case eval e exp of 
                VPair l r  -> l
                _          -> error "Error de run-time, fst espera un par"
eval e (Sndt exp)            = case eval e exp of 
                VPair l r  -> r
                _          -> error "Error de run-time, snd espera un par"

eval e (Zerot)               = VNum VZero
eval e (Suct nv)             = case eval e nv of
        (VNum VZero)     -> VNum (VSuc VZero)
        (VNum (VSuc v) ) -> VNum (VSuc (VSuc v))
        _                -> error "(Eval-vsuc) Se esperaba un valor numérico"


eval e (Rect t1 t2 t3)       = case eval e t3 of
        VNum VZero    -> eval e t1
        VNum (VSuc n) -> eval e ((t2 :@: (Rect t1 t2 t)) :@: t)
                where t = quoten n
        _             -> error "(Eval-R) Se esperaba un valor numérico en el tercer argumento"

-----------------------
--- quoting
-----------------------

quote :: Value -> Term
quote (VLam t f) = Lam t f
quote (VUnit   ) = UT
quote (VPair l r)= Pairt (quote l) (quote r)
quote (VNum x)   = quoten x


quoten VZero     = Zerot
quoten (VSuc nv) = Suct (quoten nv)
----------------------
--- type checker
-----------------------

-- type checker
infer :: NameEnv Value Type -> Term -> Either String Type
infer = infer' []

-- definiciones auxiliares
ret :: Type -> Either String Type
ret = Right

err :: String -> Either String Type
err = Left

(>>=) :: Either String Type -> (Type -> Either String Type) -> Either String Type
(>>=) v f = either Left f v
-- fcs. de error

matchError :: Type -> Type -> Either String Type
matchError t1 t2 = err $ "se esperaba " ++
                         render (printType t1) ++
                         ", pero " ++
                         render (printType t2) ++
                         " fue inferido."

notfunError :: Type -> Either String Type
notfunError t1 = err $ render (printType t1) ++ " no puede ser aplicado."

notfoundError :: Name -> Either String Type
notfoundError n = err $ show n ++ " no está definida."

infer' :: Context -> NameEnv Value Type -> Term -> Either String Type
infer' c _ (Bound i) = ret (c !! i)
infer' _ e (Free n) = case lookup n e of
                        Nothing -> notfoundError n
                        Just (_,t) -> ret t
infer' c e (t :@: u) = infer' c e t >>= \tt -> 
                       infer' c e u >>= \tu ->
                       case tt of
                         Fun t1 t2 -> if (tu == t1) 
                                        then ret t2
                                        else matchError t1 tu
                         _         -> notfunError tt
infer' c e (Lam t u) = infer' (t:c) e u >>= \tu ->
                       ret $ Fun t tu


infer' c env (Hast exp t)  = infer' c env exp >>= \tt ->
        if tt==t then ret t else matchError t tt


infer' c e UT             = ret Unit


infer' c e (Pairt l r)       = infer' c e l >>= \tl ->
                               infer' c e r >>= \tr ->
                               ret (Pair tl tr)                                 


infer' c e (Fstt exp)        = infer' c e exp >>= \te ->
                               case te of (Pair t _) -> ret t
                                          _          -> err "fst esperaba un par (infer-snd)"
infer' c e (Sndt exp)        = infer' c e exp >>= \te ->
                               case te of (Pair _ t) -> ret t
                                          _          -> err "snd esperaba un par (infer-snd)"
infer' c e Zerot             = ret Nat
infer' c e (Suct x)          = infer' c e x >>= \tx -> case tx of
                                        Nat -> ret Nat
                                        _   -> matchError Nat tx

infer' c e (Rect t1 t2 t)      = infer' c e t1 >>= \tt1 ->
                                 infer' c e t2 >>= \tt2 ->
                                 infer' c e t  >>= \tt  ->
                                 case tt of 
                                        Nat -> if tt2 == Fun tt1 (Fun Nat tt1) then ret tt1 else matchError (Fun tt1 (Fun Nat tt1)) tt2 
                                        _   -> matchError Nat tt 
                                                 
----------------------------------
