fid = fopen('../test-signals/test_signal2.txt');
data1 = textscan(fid, '%s');
fclose(fid);

data1 = cellfun(@bin2dec, data1, 'UniformOutput', false);
data1 = cell2mat(data1);

fid = fopen('test_signal2.txt');
data2 = textscan(fid, '%s', 'Headerlines', 3);
fclose(fid);

data2 = cellfun(@hex2dec, data2, 'UniformOutput', false);
data2 = cell2mat(data2);

hold on;
plot(data1);
plot(data2);
