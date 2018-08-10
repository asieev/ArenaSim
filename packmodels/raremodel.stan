data {
  int<lower=0> N;
  int<lower=1,upper=4> y[N];
  real<lower=0,upper=40> r_pt[N];
  real<lower=0,upper=40> m_pt[N];
  int<lower=0> N_example;
}
parameters {
//  real<lower=0,upper = 1> base_prob;
  real<lower=0,upper = 1> rc;
//  real<lower=0,upper = 1> mc;
  real<lower=0,upper = .06> rwc_base;
  real<lower=0, upper = 1.0/30.0> rwc_inc;
  real<lower=0,upper = .06> mwc_base;
  real<lower=0, upper = 1.0/30.0> mwc_inc;
}
transformed parameters {
  vector[4] p[N];
  for(i in 1:N) {
    p[i][2] = rwc_base + rwc_inc * r_pt[i];
    p[i][4] = mwc_base + mwc_inc * m_pt[i];


    p[i][1] = rc * (1.0 - p[i][2] - p[i][4]);
    p[i][3] = 1.0 - p[i][1] - p[i][2] - p[i][4];
  }
}
model {
  for(i in 1:N) {
    y[i] ~ categorical(p[i]);
  }
}
generated quantities {
  vector[4] p_eff;
  int eff_rwc = 0;
  int eff_mwc = 0;
  int eff_r = 0;
  int eff_m = 0;

  for(i in 1:4) {
    p_eff[i] = mean( p[:,i] );
  }
  {
    int gq_r_pt = 0;
    int gq_m_pt = 0;
    vector[4] gqp;
    int res;

    for(i in 1:N_example) {
      gqp[2] = rwc_base + rwc_inc * gq_r_pt;
      gqp[4] = mwc_base + mwc_inc * gq_m_pt;

      gqp[1] = rc * (1 - gqp[2] - gqp[4]);
      gqp[3] = 1.0 - gqp[1] - gqp[2] - gqp[4];

      res = categorical_rng(gqp);

      if(res == 2) {
        eff_rwc += 1;
        gq_r_pt = 0;
      } else {
        gq_r_pt += 1;
      }

      if(res == 4) {
        eff_mwc += 1;
        gq_m_pt = 0;
      } else {
        gq_m_pt += 1;
      }

      if(res == 1) {
        eff_r += 1;
      }

      if(res == 3) {
        eff_m += 1;
      }
    }

  }
}
