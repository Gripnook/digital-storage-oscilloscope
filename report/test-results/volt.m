data = csvread('volt.csv', 1, 0);

f = @(v) 1 + 1./v;

hold on;
plot(data(:,1), data(:,3), 'x', 'LineWidth', 1.2);
plot(data(:,1), f(data(:,1)), '--');
grid on;
xlabel('Voltage (V)');
ylabel('% error');
axis([0 4 0 10]);
legend('Measurements', '1 % + 10 mV');
