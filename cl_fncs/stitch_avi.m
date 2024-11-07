function stitch_avi(ffn_in,ffn_stitched,firstConvert)
% stitch_avi(ffn_in,ffn_stitched,[firstConvert])
% 
% uses ffmpeg to create lossless compression of movies and then stitch them
% together.
%
% IMPORTANT NOTE: files will be stitched together in the order they are
% passsed to ffn_in. Make certain the order is correct before passing to
% this function.
%
% ffn_in : ordered cell array of movie filenames
% ffn_stitched : supplied filename to write the final stitched file
% firstConvert : first runs, ffmpeg -i "original.avi" -c:v ffv1 -level 3 -preset slow -r 20 "converted.avi"

if nargin < 3 || isempty(firstConvert), firstConvert = false; end

ffn_in = cellstr(ffn_in);


tmppth = tempdir;

tmpfn = [tempname,'.txt'];



if firstConvert
    ffn_tmp = cell(size(ffn_in));

    fprintf("converting ")

    for i = 1:length(ffn_in)
        ffn_tmp{i} = fullfile(tmppth,sprintf("tmp_%i.avi",i));

        cmd_cvt = sprintf('ffmpeg -i "%s" -c:v ffv1 -level 3 -preset slow -r 20 "%s"', ...
            ffn_in{i},ffn_tmp{i});

        [status,cmdout] = system(cmd_cvt);

        fprintf(".")
    end
    fprintf(" done\n")
else
    ffn_tmp = ffn_in;
end

fid = fopen(tmpfn,'w');
cellfun(@(a) fprintf(fid,"file '%s'\n",a),ffn_tmp);
fclose(fid);

fprintf("stitching ...")
cmd_stitch = sprintf('ffmpeg -f concat -safe 0 -i "%s" -c copy "%s"',tmpfn,ffn_stitched );

[status,cmdout] = system(cmd_stitch);

if firstConvert
    cellfun(@delete,ffn_tmp);
end
delete(tmpfn);

fprintf(" done\n")