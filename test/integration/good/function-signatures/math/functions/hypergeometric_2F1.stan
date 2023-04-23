transformed data {
  real a;
  a = hypergeometric_2F1(1, 1, 1, 0.4);
  a = hypergeometric_2F1(1, 10, 11, -2.5);
  a = hypergeometric_2F1(1, 10, 11, 0.5);
  a = hypergeometric_2F1(1, 10, 11, 1);
}  
parameters {
  real<lower=0, upper=1> p;
  real<lower=0> b;
}
transformed parameters {
  real c;
  c = hypergeometric_2F1(1, 1, 1, 1 - p / (p - 1/2);
  c = hypergeometric_2F1(1, 10, 11, 1 - 0.2 / (p-1/2));
  c = hypergeometric_2F1(1, 10, 11, p);
  c = hypergeometric_2F1(1, b, b, 1);
}
model {
  b ~ normal(0, 1);
}
