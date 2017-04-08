T = 1024;
up = 2;
t = 1:T;
tt = (0:up:T-1)+1;
f = @(t) 2048 + 1024*sin(2*pi*t/T);
f = upsample(f(tt), up);

%plot(t, f);

fid = fopen('test_signal1.txt', 'w');
for i = t
    fprintf(fid, '%012s\n', dec2bin(f(i)));
end
fclose(fid); % close your file
