%==========================================================================
% 이론적 Rician 기반 임계 σ 계산
%==========================================================================
% 1) 기본 파라미터
D          = 10;            % eVTOL 최대 길이 [m]
dist_crit  = 1.5 * D;       % 평균 중심 간 거리 ν [m]
p95        = 0.05;          % 목표 충돌 확률 5% (95% 신뢰도)
p99        = 0.01;          % 목표 충돌 확률 1% (99% 신뢰도)

% 2) Rician CDF 조건 f(σ)=0 정의
%    f(σ,p) = [1 - Q1(dist_crit/σ, D/σ)] - p_target
f = @(sigma, p_target) 1 - marcumq(dist_crit./sigma, D./sigma) - p_target;

% 3) 초기 추정 및 fzero로 σ 풀이
sigma0 = D/2;  % 초기값: D/2 정도로 시작
sigma_95 = fzero(@(s) f(s, p95), sigma0);
sigma_99 = fzero(@(s) f(s, p99), sigma0);

% 4) 결과 출력
fprintf('이론적 95%% 신뢰도 σ = %.3f m (P(R< D)=%.2f%%)\n', sigma_95, p95*100);
fprintf('이론적 99%% 신뢰도 σ = %.3f m (P(R< D)=%.2f%%)\n', sigma_99, p99*100);

%==========================================================================
% 5) σ 대 충돌확률 그래프
%==========================================================================
sigma_vals = linspace(0.01,5,500);
prob_vals  = arrayfun(@(s) 1 - marcumq(dist_crit/s, D/s), sigma_vals);

figure;
plot(sigma_vals, prob_vals*100, 'LineWidth',2);
hold on;
yline(p95*100, '--r','95% 기준');
yline(p99*100, '--g','99% 기준');
xlabel('σ [m]'); ylabel('충돌 확률 P(R<D) [%]');
title('Rician 분포 이론 기반 σ에 따른 충돌확률');
grid on;
legend('P(R<D)','5% 기준','1% 기준','Location','best');
