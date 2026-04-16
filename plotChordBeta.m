chord = [0.3908 0.4137 0.4838 0.3483 0.4053 0.4099 0.3563 0.3689 0.3595 0.3186 0.2284 0.2566 0.2780 0.1911 0.1809];
beta = [0.8290 0.8245 0.7798 0.6529 0.6537 0.5182 0.4904 0.3883 0.4506 0.3688 0.2588 0.2521 0.4365 0.1976 0.2233];

% Plot on stacked subplots
figure;
tiledlayout(2,1);

nexttile;
plot(chord, '-o','Color','r');
title('Chord Distribution');
xlabel('Index');
ylabel('Chord');

nexttile;
plot(beta, '-o', 'Color','b');
title('Beta Distribution');
xlabel('Index');
ylabel('Beta');

chord_s = smoothdata(chord, 'movmean', 3);
beta_s  = smoothdata(beta,  'movmean', 3);

% Enforce monotonic decreasing
chord_mono = chord_s;
beta_mono  = beta_s;

for i = 2:length(chord_mono)
    chord_mono(i) = min(chord_mono(i), chord_mono(i-1));
    beta_mono(i)  = min(beta_mono(i),  beta_mono(i-1));
end

chord_final = chord_mono;
beta_final = beta_mono;

fprintf('[%.4f ', chord_final(1));
fprintf('%.4f ', chord_final(2:end-1));
fprintf('%.4f]\n', chord_final(end));

fprintf('[%.4f ', beta_final(1));
fprintf('%.4f ', beta_final(2:end-1));
fprintf('%.4f]\n', beta_final(end));

figure;
tiledlayout(2,1);

nexttile;
plot(chord, 'o-'); hold on;
plot(chord_final, 'r-', 'LineWidth', 2);
legend('Original','Processed');
title('Chord');

nexttile;
plot(beta, 'o-'); hold on;
plot(beta_final, 'r-', 'LineWidth', 2);
legend('Original','Processed');
title('Beta');