Data = readtable('study2_data_jump.csv');
Data = Data{:,:};
RemoveOutlier = true;

%% Check Participant accuracy
paccuracy = zeros(18, 1);
for i = 1:24
    tar = equq(Data(:, 1), i);
    paccuracy(i) = mean(Data(tar, 8));
end

%% Data Pre-processing
combD_t = [1.333333, 1.333333, 1, 1];
combW_t = [0.2666667, 0.4, 0.2, 0.3];
pos = 0;
meantimeList = zeros(12, 1);
meanerrorList = zeros(12, 1);
ksResults = zeros(12, 1);
muList = zeros(12, 1);
sigmaList = zeros(12, 1);
para = zeros(12, 3); 
delNum = 0;
output_table = [];
for comb = 1:4
    for R_t = [0.4, 0.6, 0.8]
        pos = pos + 1;        
        D_t = combD_t(comb);
        W_t = combW_t(comb);
        para(pos, 1) = D_t; para(pos, 2) = W_t; para(pos, 3) = R_t;
        tar = equq(Data(:, 2), D_t) & equq(Data(:, 3), W_t) & equq(Data(:, 4), R_t);
        parList = Data(tar, 1); 
        timeList = Data(tar, 7);
        errorList = Data(tar, 8);
        meantimeList(pos) = mean(timeList);
        meanerrorList(pos) = mean(errorList);
        % Remove Outlier
        if (RemoveOutlier) 
            s = size(timeList, 1);
            stdtimeList = std(timeList);
            tar = timeList < meantimeList(pos) + 3 * stdtimeList & ...
                timeList > meantimeList(pos) - 3 * stdtimeList;
            timeList = timeList(tar);
            errorList = errorList(tar);
            parList = parList(tar);
            delNum = delNum + s - size(timeList, 1);
            meantimeList(pos) = mean(timeList);
            meanerrorList(pos) = mean(errorList);
        end
        % create new table
        output_table = [output_table; parList repmat(para(pos,:),size(timeList, 1), 1) timeList errorList];
        % Normalization and Normality Test
        listNorm_Time = (timeList-mean(timeList))/std(timeList);
        ksResults(pos) = kstest(listNorm_Time);
        % MLE
        phat = mle(timeList);
        muList(pos) = phat(1);
        sigmaList(pos) = phat(2);
    end
end
meanerrorList = 1 - meanerrorList;
muList_abs = muList + para(:,3) - para(:,1);

%% Output Table
%csvwrite("Jump_RmOutlier.csv", output_table);

%% Our Research
% Note D_t = para(:,1); W_t = para(:,2); R_t = para(:,3);
X = [para(:,1)-para(:,3), para(:,2), para(:,3)];
simple_mdl_mu_abs = fitlm(X,muList_abs);
simple_mdl_mu_abs
pred_mu_abs = predict(simple_mdl_mu_abs,[para(:,1)-para(:,3), para(:,2), para(:,3)]);

%corrcoef(muList, pred_mu)
%corrcoef(muList_abs, pred_mu_abs)
simple_mdl_mu_abs.ModelCriterion.AIC
simple_mdl_mu_abs.ModelCriterion.BIC
%https://au.mathworks.com/help/econ/information-criteria.html
sqrt(immse(muList_abs, pred_mu_abs))
mae(muList_abs, pred_mu_abs)

%% sigma fitting 
X = [para(:,1)-para(:,3), para(:,2), para(:,3)];
mdl_sigma = fitlm(X,sigmaList);
mdl_sigma

pred_sigma = predict(mdl_sigma,[para(:,1)-para(:,3), para(:,2), para(:,3)]);
mdl_sigma.ModelCriterion.AIC
mdl_sigma.ModelCriterion.BIC
sqrt(immse(sigmaList, pred_sigma))
mae(sigmaList, pred_sigma)

%% error fitting
fitMu_abs = predict(simple_mdl_mu_abs,[para(:,1)-para(:,3), para(:,2), para(:,3)]);
fitSigma = predict(mdl_sigma,[para(:,1)-para(:,3), para(:,2), para(:,3)]);

%%% No deviation version
%fun = @(t) exp(-(t-fitMu_abs).^2./(2.*fitSigma.^2))./(fitSigma.*sqrt(2.*pi));
%E = zeros(24, 1);
%for i = (1:24)
%    integ = integral(fun,0,para(i,2),'ArrayValued',true);
%    E(i) = 1 - integ(i);
%end
%corrcoef(E, meanerrorList)

%%% Deviation one level
E_erf = 1-(1/2).*(erf((para(:,2)-fitMu_abs)./(fitSigma.*sqrt(2))) + erf((fitMu_abs)./(fitSigma.*sqrt(2))));
R = corrcoef(E_erf, meanerrorList);
R.^2
sqrt(immse(E_erf, meanerrorList))
mae(E_erf, meanerrorList)
%error_19 = sqrt(immse(E, meanerrorList));
%error_19


% Plot predicted vs. empirical
p1 = plot(linspace(0,1,50), linspace(0,1,50))
set(p1,'LineWidth',1.5)
hold on;
p2 = plot(meanerrorList, E_erf, 'k.', 'MarkerSize', 10)
hold off;

%% 3D plot related to all parameters - mu
sc = scatter3(para(:,1), para(:,3), muList_abs, '*', 'r')
set(sc,'LineWidth',1.5)
hold on;
spre = scatter3(para(:,1), para(:,3), pred_mu_abs, 'o', 'k')
hold off;

%% 3D plot related to all parameters - sigma
sc = scatter3(para(:,1), para(:,3), sigmaList, '*', 'r')
set(sc,'LineWidth',1.5)
hold on;
spre = scatter3(para(:,1), para(:,3), pred_sigma, 'o', 'k')
hold off;

%% Simplified Model
% Note D_t = para(:,1); W_t = para(:,2); R_t = para(:,3);
X = [para(:,1), para(:,3)];
simple_mdl_mu_abs = fitlm(X,muList_abs);
simple_mdl_mu_abs
pred_mu_abs = predict(simple_mdl_mu_abs,[para(:,1), para(:,3)]);

simple_mdl_mu_abs.ModelCriterion.AIC
simple_mdl_mu_abs.ModelCriterion.BIC
mae(muList_abs, pred_mu_abs)

% sigma fitting -- Note: x(1) = c_sigma;
X = [para(:,1)];
simple_mdl_sigma = fitlm(X,sigmaList);
simple_mdl_sigma

pred_sigma = predict(simple_mdl_sigma,X);
simple_mdl_sigma.ModelCriterion.AIC
simple_mdl_sigma.ModelCriterion.BIC
mae(sigmaList, pred_sigma)

fitMu_simple_abs = predict(simple_mdl_mu_abs,[para(:,1), para(:,3)]);
fitSigma_simple = predict(simple_mdl_sigma,[para(:,1)]);
E_erf16 = 1-(1/2).*(erf((para(:,2)-fitMu_simple_abs)./(fitSigma_simple.*sqrt(2))) ...
    + erf((fitMu_simple_abs)./(fitSigma_simple.*sqrt(2))));
R = corrcoef(E_erf16, meanerrorList);
R.^2
%error_16 = sqrt(immse(E_erf16, meanerrorList))
mae(E_erf16, meanerrorList)

p1 = plot(linspace(0,1,50), linspace(0,1,50))
set(p1,'LineWidth',1.5)
hold on;
plot(meanerrorList, E_erf16, 'k.', 'MarkerSize', 10)
hold off;

%% Interact Model
X = [para(:,1), para(:,3), para(:,1).*para(:,3)];
simple_mdl_mu_abs = fitlm(X,muList_abs);
simple_mdl_mu_abs
pred_mu_abs = predict(simple_mdl_mu_abs,[para(:,1), para(:,3), para(:,1).*para(:,3)]);

simple_mdl_mu_abs.ModelCriterion.AIC
simple_mdl_mu_abs.ModelCriterion.BIC
mae(muList_abs, pred_mu_abs)

% sigma fitting -- Note: x(1) = c_sigma;
X = [para(:,1)];
simple_mdl_sigma = fitlm(X,sigmaList);
simple_mdl_sigma

pred_sigma = predict(simple_mdl_sigma,X);
simple_mdl_sigma.ModelCriterion.AIC
simple_mdl_sigma.ModelCriterion.BIC
mae(sigmaList, pred_sigma)

fitMu_simple_abs = predict(simple_mdl_mu_abs,[para(:,1), para(:,3), para(:,1).*para(:,3)]);
fitSigma_simple = predict(simple_mdl_sigma,[para(:,1)]);
E_erf16 = 1-(1/2).*(erf((para(:,2)-fitMu_simple_abs)./(fitSigma_simple.*sqrt(2))) ...
    + erf((fitMu_simple_abs)./(fitSigma_simple.*sqrt(2))));
R = corrcoef(E_erf16, meanerrorList);
R.^2
%error_16 = sqrt(immse(E_erf16, meanerrorList))
mae(E_erf16, meanerrorList)

p1 = plot(linspace(0,1,50), linspace(0,1,50))
set(p1,'LineWidth',1.5)
hold on;
plot(meanerrorList, E_erf16, 'k.', 'MarkerSize', 10)
hold off;

%%
function m = equq(x, y)
    m = abs(x - y) < 0.001;
end
