  $ $TESTDIR/../..//../../_build/default/stanc.exe "$TESTDIR/../..//ode/adams/bad_fun_type.stan"
  Semantic error at file ".*/examples-bad/ode/adams/../..//ode/adams/bad_fun_type.stan", line 27, characters 11-336: (re)
  Ill-typed arguments supplied to function integrate_ode_adams. Available signatures: 
  ((real, real[], real[], data real[], data int[]) => real[], real[], data real, data real[], real[], data real[], data int[], data real, data real, data real) => real[][]
  ((real, real[], real[], data real[], data int[]) => real[], real[], data real, data real[], real[], data real[], data int[]) => real[][]
  Instead supplied arguments of incompatible type: (real[], real[], real[], real[], int[]) => real[], real[], real, real[], real[], real[], int[].
  [1]
