$$
\definecolor{red}{RGB}{208,25,25}
\definecolor{orange}{RGB}{242,113,28}
\definecolor{yellow}{RGB}{251,189,8}
\definecolor{olive}{RGB}{181,204,24}
\definecolor{green}{RGB}{33,186,69}
\definecolor{teal}{RGB}{0,181,173}
\definecolor{blue}{RGB}{33,133,208}
\definecolor{violet}{RGB}{100,53,201}
\definecolor{purple}{RGB}{163,51,200}
\definecolor{pink}{RGB}{224,57,151}
\definecolor{brown}{RGB}{165,103,63}
\definecolor{gray}{RGB}{118,118,118}
\definecolor{black}{RGB}{27,28,29}
\newcommand{\conc}{\textcolor{blue}{\Rightarrow}}
\newcommand{\def}{\textcolor{blue}{\text{def}}}
\newcommand{\defeq}{\textcolor{blue}{:=}}
\newcommand{\deflr}{\textcolor{blue}{:\leftrightarrow}}
\newcommand{\to}{\rightarrow}
\newcommand{\lr}{\leftrightarrow}
\newcommand{\gives}{\Rightarrow}
\newcommand{\suffices}{\Leftarrow}
\newcommand{\rw}{\Leftrightarrow}
\newcommand{\inner}[2]{\left\langle\strut#1,#2\right\rangle}
\newcommand{\norm}[1]{\left\Vert\strut#1\right\Vert}
\newcommand{\abs}[1]{\left\vert\strut#1\right\vert}
\newcommand{\T}{^\mathsf T}
\newcommand{\H}{^\mathsf H}
\newcommand{\d}{\ \mathrm{d}}
\newcommand{\i}{\mathrm{i}\mkern1mu}
\newcommand{\N}{\mathbb{N}}
\newcommand{\Z}{\mathbb{Z}}
\newcommand{\Q}{\mathbb{Q}}
\newcommand{\R}{\mathbb{R}}
\newcommand{\C}{\mathbb{C}}
\DeclareMathOperator{\dom}{\mathrm{Dom}}
\DeclareMathOperator{\ran}{\mathrm{Ran}}
\DeclareMathOperator{\ker}{\mathrm{Ker}}
\DeclareMathOperator{\im}{\mathrm{Im}}
\DeclareMathOperator{\rank}{\mathrm{rank}}
\DeclareMathOperator{\null}{\mathrm{null}}
\DeclareMathOperator{\det}{\mathrm{det}}
\DeclareMathOperator{\gcd}{\mathrm{gcd}}
\DeclareMathOperator{\lcm}{\mathrm{lcm}}
\textcolor{blue}{\rule{600px}{1.0pt}}
$$

## Joinable state spaces

- **(State spaces)**
  $\def$ $(S, A)$ is state space
  $\deflr$ (i) $S, A$ are countable sets;
  (ii) $A \subseteq (S\to S)$;
  (iii) $\text{id}\in A$;
  (iv) forall $f,g\in A$, $g\circ f \in A$.
  _-- An element $s\in S$ is called a "(valid) state", while $f\in A$ is a "(valid) action"._
  _-- Conditions (iii) and (iv) together say that "zero or more valid actions performed sequentially is still a valid action"._
  _-- For example, $S = \N$ and $A = \{n\mapsto n+i \mid i \in \N\}$ (trivially bijective to $\N$) form the state space of a simple counting app._
- **(Products of state spaces)**
  $(S, A)$ is state space,
  $(T, B)$ is state space,
  $\def$ $(S, A)\times (T, B)$ $\defeq$ $(\{(s, t)\mid s\in S,\ t\in T\}, \{(s, t) \mapsto (f(s), g(t)) \mid f\in A,\ g\in B\})$.
  $\conc$ $(S, A)\times (T, B)$ is state space.
  _-- Check axioms._
  _-- Corollary: for any finite index set $I$, if (forall $i\in I$, $(S_i, A_i)$ is state space), then so is the iterated product $\prod_{i\in I} (S_i, A_i)$._
  _-- Remark: this simply means that it is possible to "decompose" a state space into a product of independent parts._
- **(Joinability)**
  $(S, A)$ is state space,
  $\def$ $(S, A)$ is joinable by $\wedge: S\times S\to S$
  $\deflr$ exists partial order $\leq$ on $S$ such that
  (i) $(S, \leq)$ is semilattice;
  (ii) forall $s\in S$ and $f\in A$, $s \leq f(s)$;
  (iii) forall $s,t\in S$, $s \wedge t$ is the join (least upper bound) of $s$ and $t$.
  _-- Notation: if there is no ambiguity, I will simply say "$(S, A)$ is joinable (state space)" and use "$\wedge$" for the join operation._
  _-- Remark: the join operation "$\wedge$" takes whole $s$ as input. In practice, we seldom want to send the whole application state $s$ over network..._
- **(Products of joinable state spaces)**
  $(S, A)$ is joinable,
  $(T, B)$ is joinable,
  $\conc$ $(S, A)\times (T, B)$ is joinable by $(s_1, t_1), (s_2, t_2) \mapsto (s_1 \wedge s_2,\ t_1 \wedge t_2)$.
  _-- Check axioms (using partial order $(s_1,t_1)\leq (s_2,t_2)$ $:\lr$ $s_1\leq s_2$ and $t_1\leq t_2$)._
  _-- Corollary: for any finite index set $I$, if (forall $i\in I$, $(S_i, A_i)$ is joinable), then so is the iterated product $\prod_{i\in I} (S_i, A_i)$._
  _-- Remark: to join is to join independent parts separately._
- **(Delta- and gamma-joinability)**
  $(S, A)$ is joinable,
  $\def$ $(S, A)$ is delta-joinable by $\Delta: S\times A\times A\to S$
  $\deflr$ forall $s\in S$ and $f,g\in A$, $\Delta(s,f,g) = (f(s)\wedge g(s))$.
  _-- "Three-way merge" using common ancestor and changes._
  _-- Remark: it is easy to see that joinability implies delta-joinability (simply implement $\Delta$ by first applying changes and then joining), so the new definition is mathematically "meaningless". Practically, however, it is possible to have more efficient direct implementations for $\Delta$. (In mathematics, we think "extensionally" equal functions to be "the same"; in programming, it makes sense to consider their "intensional" difference.)_
  _-- Remark: in order for this to be actually useful, we must be able to "revert" the local state to a previous snapshot $s$, while separating later actions._
  $\def$ $(S, A)$ is gamma-joinable by $\Gamma: S\times A\to S$
  $\deflr$ forall $s\in S$ and $f,g\in A$, $\Gamma(f(s), g) = (f(s)\wedge g(s))$.
  _-- "Asymmetric merge" using "our" state and "their" changes._
  _-- Remark: gamma-joinability is a stronger condition than joinability. For some data structures, such $\Gamma$ is possible to implement. If this is true, then there is no need to retain older state snapshots. A history of actions is still needed._
- **(Properties of gamma-joinable spaces)**
  $(S, A)$ is gamma-joinable by $\Gamma$,
  $\conc$ $\Gamma = (s, f) \mapsto f(s)$. _-- $\Gamma$ is same as `apply`._
  _-- For any $s\in S$ and $f\in A$, $\Gamma(s, f) = \Gamma(\text{id}(s), f) = (\text{id}(s)\wedge f(s)) = (s\wedge f(s)) = f(s)$._
  _-- Corollary: a joinable space is gamma-joinable **if and only if** forall $s\in S$ and $f,g\in A$, $g(f(s)) = (f(s)\wedge g(s))$._
  $\conc$ for any $s\in S$ and $f\in A$, $f(f(s)) = f(s)$. _-- Idempotence._
  _-- Calculate $f(f(s)) = (f(s)\wedge f(s)) = f(s)$._
  $\conc$ for any $s\in S$ and $f,g\in A$, $g(f(s)) = f(g(s))$. _-- Commutativity._
  _-- Calculate $g(f(s)) = (f(s)\wedge g(s)) = (g(s)\wedge f(s)) = f(g(s))$._
  _-- Remark: if $A$ is generated from a set of "atomic actions" $\{f_i,\ldots\}_{i\in\N}$, then every element $f\in A$ corresponds to a finite set $\{f_{k_1},\ldots,f_{k_n}\}$ such that $f = f_{k_1}\circ\ldots\circ f_{k_n}$ (i.e. duplicates and ordering do not matter)._
- **(LWW-registers are gamma-joinable)**
  $X$ is totally ordered set, _-- The set of possible values._
  $S := (\R\cup\{-\infty,+\infty\})\times X$, _-- The set of timestamped values._
  $A := \{s \mapsto \max\{s, (t, x)\} \mid t\in\R\cup\{-\infty,+\infty\},\ x\in X\}$, _-- The set of timestamped actions._
  $\def$ $\text{Reg}(X)$ $\defeq$ $(S, A)$.
  $\conc$ $\text{Reg}(X)$ is gamma-joinable.
  _-- Easy to check (using the "natural" total order on $S$)._
- **(LWW-graphs are gamma-joinable)**
  $V, E$ are finite sets, _-- Index sets of vertices and edges._
  $X,Y$ are totally ordered sets, _-- Sets of possible values on vertices and edges._
  $\def$ $\text{Graph}(V,E,X,Y)$ $\defeq$ $\prod_{v\in V}\text{Reg}(X\cup\{\bot\}) \times \prod_{e\in E}\text{Reg}(Y\cup\{\bot\})$.
  $\conc$ $\text{Graph}(V,E,X,Y)$ is gamma-joinable.
  _-- By previous results (products of joinable state spaces are joinable, so are gamma-joinable; although more efficient implementation exists)._
  _-- Remark: a LWW-graph is just a product of many LWW-registers. A special value $\bot$ is used to indicate absence of a particular vertex or edge. In case an edge has a normal value but one of its endpoints has value $\bot$ (i.e. marked as absent), the edge is disregarded._
- **(Longest-array-sets are gamma-joinable)**
  $I$ is finite set,
  $X$ is totally ordered set,
  $\def$ $\text{Log}(I, X)$ $\defeq$ $\prod_{i\in I} \bigcup_{n=0}^\infty X^n$.
  $\conc$ $\text{Log}(I, X)$ is gamma-joinable, where forall $\vec x\in X^n$ and $\vec y\in X^m$, $\vec x\leq \vec y$ $:\lr$ $n < m$ or ($n=m$ and $\vec x \leq \vec y$ in lexicographical order).
  *-- By previous results.*
  *-- Remark: if each client only appends to the array corresponding to a distinct $i\in I$, this structure can be used as an "event log" of clients and can be gamma-joined efficiently (for each $i\in I$, exchange lengths and transfer tails).*

## Quotient of histories

- TODO: spell out the theory of (decentralised) OT
- TODO: derive CP1 and CP2 from well-definedness of functions on quotient structures
