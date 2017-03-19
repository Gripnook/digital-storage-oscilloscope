% 4-bit grayscale converter

src = uint32(imread('background.bmp'));
data = floor(double(rgb2gray(src)) / 16);
[m,n] = size(data);

N = m*n;
word_len = 4;

fid = fopen('background.mif', 'w');
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
