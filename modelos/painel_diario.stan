// Etapa 11 (secao 17 do plano): logit hierarquico diario com estado comum AR(1).
// logit(p_id) = mu_a + sigma_a * u_i + X_id' gamma + Z_id' xi + v_d
// v_d = phi v_{d-1} + sigma_v eps_d; v_1 ~ N(0, sigma_v / sqrt(1 - phi^2)).
// Parametrizacao nao centrada para interceptos e estados. Dias sem alvos
// entram na evolucao do estado sem verossimilhanca observacional.
data {
  int<lower=1> N;
  int<lower=1> I;
  int<lower=1> D;                       // grade completa de dias de calendario
  int<lower=0> Kx;
  int<lower=0> Kz;                      // 0 em B2; atributos de rede em B3/B4
  array[N] int<lower=1, upper=I> ativo;
  array[N] int<lower=1, upper=D> dia;
  matrix[N, Kx] X;
  matrix[N, Kz] Z;
  array[N] int<lower=0, upper=1> y;
  real mu_a_media;                      // -3 no protocolo
  real<lower=0> escala_coef;            // 0.5 no protocolo; 0.25 e 1 em sensibilidade
}
parameters {
  real mu_a;
  real<lower=0> sigma_a;
  vector[I] u;
  vector[Kx] gamma;
  vector[Kz] xi;
  real<lower=0> sigma_v;
  real<lower=-0.95, upper=0.95> phi;
  vector[D] eps;
}
transformed parameters {
  vector[D] v;
  v[1] = sigma_v / sqrt(1 - square(phi)) * eps[1];
  for (d in 2:D) v[d] = phi * v[d - 1] + sigma_v * eps[d];
}
model {
  mu_a ~ normal(mu_a_media, 1.5);
  sigma_a ~ normal(0, 1);
  u ~ std_normal();
  gamma ~ normal(0, escala_coef);
  xi ~ normal(0, escala_coef);
  sigma_v ~ normal(0, 0.3);
  phi ~ normal(0, 0.5);
  eps ~ std_normal();
  {
    vector[N] eta = mu_a + sigma_a * u[ativo] + v[dia];
    if (Kx > 0) eta += X * gamma;
    if (Kz > 0) eta += Z * xi;
    y ~ bernoulli_logit(eta);
  }
}
generated quantities {
  // Simulacao a priori/posteriori pode ser feita em R a partir dos draws.
  real v_ultimo = v[D];
}
