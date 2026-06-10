%==========================================================================  
% eVTOL 중심간 충돌 확률 및 충돌 개수 Monte Carlo 시뮬레이션  
%==========================================================================  
% 기본 파라미터 설정  
D          = 10;                 % eVTOL 최대 길이 [m]  
dist_crit  = 1.5 * D;            % 기준 중심 간 거리 [m]  
num_trials = 100000;             % Monte Carlo 반복 횟수  
sigma_list = 0.01:0.01:5.0;      % 테스트할 σ 리스트 [m] (0.01m 간격)  
group_size = 1000;
num_trials = 1e6;
num_groups = num_trials / group_size;

  
% 충돌 개수 저장용
collision_counts = zeros(size(sigma_list));

for i = 1:length(sigma_list)
    sigma = sigma_list(i);

    % 위치 오차 적용
    x1 = randn(num_trials, 1) * sigma;
    y1 = randn(num_trials, 1) * sigma;
    x2 = dist_crit + randn(num_trials, 1) * sigma;
    y2 = randn(num_trials, 1) * sigma;

    % 거리 계산
    distance = sqrt((x1 - x2).^2 + (y1 - y2).^2);

    % 충돌 횟수 계산
    collision_counts(i) = sum(distance < D);
    collision_rates(i)  = collision_counts(i) / num_trials * 100; 
end

% 신뢰도 조건에 해당하는 최대 σ 찾기
p95 = 5;   % 충돌률 5% → 신뢰도 95%
p99 = 1;   % 충돌률 1% → 신뢰도 99%

idx_95 = find(collision_rates <= p95, 1, 'last');
idx_99 = find(collision_rates <= p99, 1, 'last');

fprintf('\n--- 신뢰도 결과 ---\n');
if ~isempty(idx_95)
    fprintf('95%% 신뢰도: σ ≤ %.2f m (충돌률 %.2f%%)\n', sigma_list(idx_95), collision_rates(idx_95));
else
    fprintf('95%% 신뢰도 만족하는 σ 없음\n');
end

if ~isempty(idx_99)
    fprintf('99%% 신뢰도: σ ≤ %.2f m (충돌률 %.2f%%)\n', sigma_list(idx_99), collision_rates(idx_99));
else
    fprintf('99%% 신뢰도 만족하는 σ 없음\n');
end

%시각화
figure;
bar(sigma_list, collision_counts);
xlabel('표준편차 σ [m]');
ylabel('충돌 횟수');
title('시그마별 충돌 횟수');
grid on;
