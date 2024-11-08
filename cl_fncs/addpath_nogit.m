function r = addpath_nogit(rootpth)
% r = addpath_nogit(rootpth)

sep = ";";
if ~ispc(), sep = ":"; end

pth = genpath(rootpth);

pth = split(pth,sep);

i = cellfun(@(a) isempty(a) || contains(a,'.git'),pth);

pth(i) = [];

pth = join(pth,sep);

r = addpath(char(pth));