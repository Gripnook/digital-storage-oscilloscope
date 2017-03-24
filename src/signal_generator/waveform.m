N = 100;
word_len = 8;

t = 1:N;
data = round(2^(word_len-1) * (1/2 * sin(2*pi*t/N) + 1));

fid = fopen('waveform.mif', 'w');
fprintf(fid, 'DEPTH=%d;\n', N);
fprintf(fid, 'WIDTH=%d;\n', word_len);
fprintf(fid, 'ADDRESS_RADIX = UNS;\n');
fprintf(fid, 'DATA_RADIX = HEX;\n');
fprintf(fid, 'CONTENT\t');
fprintf(fid, 'BEGIN\n');
for i = 0 : N-1
    fprintf(fid, '\t%d\t:\t%x;\n', i, data(i+1));
end
fprintf(fid, 'END;\n'); % prinf the end
fclose(fid); % close your file
