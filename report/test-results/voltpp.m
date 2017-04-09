data = csvread('voltpp.csv', 1, 0);

f = @(v) 1 + 1./v;

hold on;
plot(data(:,1), data(:,4), 'x', 'LineWidth', 1.2);
plot(data(:,1), f(data(:,2)), '--');
grid on;
xlabel('Frequency (kHz)');
ylabel('% error');
axis([0 200 0 2]);
legend('Measurements', '1 % + 10 mV');
