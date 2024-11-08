function stitch_avi(ffn_in,ffn_stitched,setFrameRate,firstConvert)
% stitch_avi(ffn_in,ffn_stitched,[setFrameRate],[firstConvert])
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

if nargin < 3, setFrameRate = []; end
if nargin < 4 || isempty(firstConvert), firstConvert = false; end

ffn_in = cellstr(ffn_in);

assert(~isempty(ffn_in));

tmppth = tempdir;

tmpfn = [tempname,'.txt'];



if firstConvert
    ffn_tmp = cell(size(ffn_in));

    fprintf("converting ")

    for i = 1:length(ffn_in)
        ffn_tmp{i} = fullfile(tmppth,sprintf("tmp_%i.avi",i));

        if isempty(setFrameRate)
            cmd_cvt = sprintf('ffmpeg -i "%s"  -vf format=gray -c:v ffv1 -level 3 -preset slow "%s"', ...
                ffn_in{i},ffn_tmp{i});
        else
            cmd_cvt = sprintf('ffmpeg -r %d -i "%s"  -vf format=gray -c:v ffv1 -level 3 -preset slow -r %d "%s"', ...
                setFrameRate,ffn_in{i},setFrameRate,ffn_tmp{i});
        end

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
if isempty(setFrameRate)
    cmd_stitch = sprintf('ffmpeg -f concat -safe 0 -i "%s" -c copy "%s"',tmpfn,ffn_stitched );
else
    cmd_stitch = sprintf('ffmpeg -r %d -f concat -safe 0 -i "%s" -c copy -r %d "%s"', ...
        setFrameRate,tmpfn,setFrameRate,ffn_stitched);
end
[status,cmdout] = system(cmd_stitch);

if firstConvert
    cellfun(@delete,ffn_tmp);
end
delete(tmpfn);

fprintf(" done\n")