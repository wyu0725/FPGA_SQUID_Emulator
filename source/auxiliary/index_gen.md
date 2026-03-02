

```c#
double phi0 = 2.068e-15;
double dt = 1.0 / 8.0;
double beta_c = double.Parse(tbxsquid_beta_c.Text);
double beta_l = double.Parse(tbxsquid_beta_l.Text);
double gamma = double.Parse(tbxsquid_gamma.Text);

double alpha_r = double.Parse(tbxsquid_alpha_r.Text);
double alpha_i = double.Parse(tbxsquid_alpha_i.Text);
double alpha_c = double.Parse(tbxsquid_alpha_c.Text);
double alpha_l = double.Parse(tbxsquid_alpha_l.Text);
double ib = 10.0 / 10.0;

double gain = double.Parse(tbxsquid_gain.Text);
double ic = double.Parse(tbxsquid_ic.Text);
double r = double.Parse(tbxsquid_r.Text);

var M = Matrix<double>.Build.Dense(2, 2);
M[0, 0] = -(gamma + 1 - alpha_r) / (beta_c * (1 - alpha_c));
M[0, 1] = gamma / (beta_c * (1 - alpha_c));
M[1, 0] = gamma / (beta_c * (1 + alpha_c));
M[1, 1] = -(gamma + 1 + alpha_r) / (beta_c * (1 + alpha_c));

double tr = M.Trace();
double det = M.Determinant();

double lambda1 = (tr - Math.Sqrt(tr * tr - 4 * det)) / 2.0;
double lambda2 = (tr + Math.Sqrt(tr * tr - 4 * det)) / 2.0;


double e1 = Math.Exp(lambda1 * dt);
double e2 = Math.Exp(lambda2 * dt);
var E = Matrix<double>.Build.DenseOfDiagonalArray(new double[] { e1, e2 });

double p1 = (e1 - 1) / lambda1;
double p2 = (e2 - 1) / lambda2;
var P = Matrix<double>.Build.DenseOfDiagonalArray(new double[] { p1, p2 });

Matrix<double> E_prime;
Matrix<double> P_prime;

if (gamma > 0)
{
    var X = Matrix<double>.Build.DenseOfArray(new double[,]
    {
        { 1, 1 },
        {
            (lambda1 * beta_c * (1 - alpha_c) + gamma + (1 - alpha_r)) / gamma,
            (lambda2 * beta_c * (1 - alpha_c) + gamma + (1 - alpha_r)) / gamma
        }
    });

    var X_inv = (gamma / ((lambda2 - lambda1) * beta_c * (1 - alpha_c))) *
        Matrix<double>.Build.DenseOfArray(new double[,]
        {
            { X[1,1], -1 },
            { -X[1,0], 1 }
        });
    
    E_prime = X * E * X_inv;
    P_prime = X * P * X_inv;

}
else 
{
    E_prime = E.Clone();
    P_prime = P.Clone();
}

double ax = E_prime[0, 0];
double bx = E_prime[0, 1];
double cx = (1 + alpha_l) * ib  / (2 * beta_c * (1 - alpha_c)) * P_prime[0, 0]
          + (1 - alpha_l) * ib / (2 * beta_c * (1 + alpha_c)) * P_prime[0, 1];
double ex = 1.0 / (Math.PI * beta_l * beta_c * (1 - alpha_c)) * P_prime[0, 0]
          - 1.0 / (Math.PI * beta_l * beta_c * (1 + alpha_c)) * P_prime[0, 1];
double dx = -2 * Math.PI * ex;
double fx = -(1 - alpha_i) / (beta_c * (1 - alpha_c)) * P_prime[0, 0];
double gx = -(1 + alpha_i) / (beta_c * (1 + alpha_c)) * P_prime[0, 1];

double ay = E_prime[1, 0];
double by = E_prime[1, 1];
double cy = (1 + alpha_l) * ib / (2 * beta_c * (1 - alpha_c)) * P_prime[1, 0]
          + (1 - alpha_l) * ib / (2 * beta_c * (1 + alpha_c)) * P_prime[1, 1];
double ey = 1.0 / (Math.PI * beta_l * beta_c * (1 - alpha_c)) * P_prime[1, 0]
          - 1.0 / (Math.PI * beta_l * beta_c * (1 + alpha_c)) * P_prime[1, 1];
double dy = -2 * Math.PI * ey;
double fy = -(1 - alpha_i) / (beta_c * (1 - alpha_c)) * P_prime[1, 0];
double gy = -(1 + alpha_i) / (beta_c * (1 + alpha_c)) * P_prime[1, 1];

double vox_ratio = (1.0 - alpha_l) * gain * ic * r / 16 * Math.PI / 1000000.0 / 2;
double voy_ratio = (1.0 + alpha_l) * gain * ic * r / 16 * Math.PI / 1000000.0 / 2;

cx /= (Math.PI);
dx /= Math.PI;
fx /= Math.PI;
gx /= Math.PI;

cy /= (Math.PI);
dy /= Math.PI;
fy /= Math.PI;
gy /= Math.PI;
```



