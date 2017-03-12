src = imread('../src/background.bmp');
data = src(:,:,1)*65536 + src(:,:,2)*256 + src(:,:,3);
[m,n] = size(data);

N = m*n;
word_len = 24;
data = reshape(data, 1, N);

fid = fopen('../src/background.mif', 'w');
fprintf(fid, 'DEPTH=%d;\n', N);
fprintf(fid, 'WIDTH=%d;\n', word_len);
fprintf(fid, 'ADDRESS_RADIX = UNS;\n'); 
fprintf(fid, 'DATA_RADIX = HEX;\n'); 
fprintf(fid, 'CONTENT\t');
fprintf(fid, 'BEGIN\n');
for i = 0 : N-1
    fprintf(fid, '\t%d\t:\t%x;\n',i, data(i+1));
end
fprintf(fid, 'END;\n'); % prinf the end
fclose(fid); % close your file
