data {
  int<lower=0> N;
  int<lower=0,upper=1> yc[N];
  int<lower=0,upper=1> yu[N];
  real<lower=0,upper=10> c_pt[N];
  real<lower=0,upper=10> u_pt[N];
}
parameters {
  real cwc_base;
  real<lower=0> cwc_inc;
  real uwc_base;
  real<lower=0> uwc_inc;
}
transformed parameters {
  real pc[N];
  real pu[N];
  for(i in 1:N) {
    pc[i] = cwc_base + cwc_inc * c_pt[i];
    pu[i] = uwc_base + uwc_inc * u_pt[i];
  }
}
model {
  cwc_base ~ normal(0, 10);
  uwc_base ~ normal(0, 10);

  cwc_inc ~ normal(1, 10);
  uwc_inc ~ normal(1, 10);

  for(i in 1:N) {
    yc[i] ~ bernoulli_logit(pc[i]);
    yu[i] ~ bernoulli_logit(pu[i]);
  }
}
generated quantities {
  real pc_eff;
  real pu_eff;

  pc_eff = mean( inv_logit(pc) );
  pu_eff = mean( inv_logit(pu) );
}
