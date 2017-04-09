data = csvread('freq.csv', 1, 0);

f = @(freq) 1 + 1./freq;

hold on;
plot(data(:,1), data(:,3), 'x', 'LineWidth', 1.2);
plot(data(:,1), f(data(:,1)), '--');
grid on;
xlabel('Frequency (kHz)');
ylabel('% error');
axis([0 200 0 1.5]);
legend('Measurements', '1 % + 10 Hz');
