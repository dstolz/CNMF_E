function update_background_parallel(obj, use_parallel)
%% update the background related variables in CNMF framework
% input:
%   use_parallel: boolean, do initialization in patch mode or not.
%       default(true); we recommend you to set it false only when you want to debug the code.

%% Author: Pengcheng Zhou, Columbia University, 2017
%% email: zhoupc1988@gmail.com

%% process parameters

try
    % map data
    mat_data = obj.P.mat_data;
    
    % folders and files for saving the results
    log_file =  obj.P.log_file;
    flog = fopen(log_file, 'a');
    log_data = matfile(obj.P.log_data, 'Writable', true); %#ok<NASGU>
    
    % dimension of data
    dims = mat_data.dims;
    d1 = dims(1);
    d2 = dims(2);
    T = dims(3);
    obj.options.d1 = d1;
    obj.options.d2 = d2;
    
    % parameters for patching information
    patch_pos = mat_data.patch_pos;
    block_pos = mat_data.block_pos;
    
    % number of patches
    [nr_patch, nc_patch] = size(patch_pos);
catch
    error('No data file selected');
end
fprintf('\n-----------------UPDATE BACKGROUND---------------------------\n'); 

% frames to be loaded for initialization
frame_range = obj.frame_range;
T = diff(frame_range) + 1;

% threshold for detecting large residuals
thresh_outlier = obj.options.thresh_outlier;

% use parallel or not
if ~exist('use_parallel', 'var')||isempty(use_parallel)
    use_parallel = true; %don't save initialization procedure
end

% options
options = obj.options;
nb = options.nb;

%% start updating the background
bg_model = obj.options.background_model;

A = cell(nr_patch, nc_patch);
C = cell(nr_patch, nc_patch);
sn = cell(nr_patch, nc_patch);
W = obj.W;
b0 = obj.b0;
b = obj.b;
f = obj.f;
for mpatch=1:(nr_patch*nc_patch)
    tmp_block = block_pos{mpatch};
    
    % find the neurons that are within the block
    mask = zeros(d1, d2);
    mask(tmp_block(1):tmp_block(2), tmp_block(3):tmp_block(4)) = 1;
    ind = (reshape(mask(:), 1, [])* obj.A>0);
    A{mpatch}= obj.A(logical(mask), ind);
    sn{mpatch} = obj.P.sn(logical(mask));
    C{mpatch} = obj.C(ind, :);
end

% check whether this is the first run of updating background components 
if strcmpi(bg_model, 'ring')
    flag_first = (length(unique(W{1}(1, :)))==2); 
else
    flag_first = (mean2(b{1})==0); 
end

if use_parallel
    parfor mpatch=1:(nr_patch*nc_patch)
        tmp_patch = patch_pos{mpatch};
        tmp_block = block_pos{mpatch};
        
        % find the neurons that are within the block
        mask = zeros(d1, d2);
        mask(tmp_block(1):tmp_block(2), tmp_block(3):tmp_block(4)) = 1;
        A_block = A{mpatch};
        sn_block = sn{mpatch};
        C_block = C{mpatch};
        
        % stop the updating B because A&C doesn't change in this area 
        if isempty(A_block) && (~flag_first)
            [r, c] = ind2sub([nr_patch, nc_patch], mpatch);
            fprintf('Patch (%2d, %2d) is done. %2d X %2d patches in total. \n', r, c, nr_patch, nc_patch);
            continue;
        end
        % use ind_patch to indicate pixels within the patch and only
        % update (W, b0) corresponding to these pixels
        mask(tmp_patch(1):tmp_patch(2), tmp_patch(3):tmp_patch(4)) = 0;
        ind_patch = logical(1-mask(tmp_block(1):tmp_block(2), tmp_block(3):tmp_block(4)));
        
        % pull data
        Ypatch = get_patch_data(mat_data, tmp_patch, frame_range, true);
        if strcmpi(bg_model, 'ring')
            % get the previous estimation
            W_old = W{mpatch};
            Ypatch = reshape(Ypatch, [], T); 
            sn_patch = sn_block(ind_patch); 
            % run regression to get A, C, and W, b0
            [W{mpatch}, b0{mpatch}] = fit_ring_model(Ypatch, A_block, C_block, W_old, thresh_outlier, sn_patch, ind_patch); 
        elseif strcmpi(bg_model, 'nmf')
            b_old = b{mpatch};
            f_old = f{mpatch}; 
            Ypatch = reshape(Ypatch, [], T); 
            sn_patch = sn_block(ind_patch); 
            [b{mpatch}, f{mpatch}] = fit_nmf_model(Ypatch, nb, A_block, C_block, b_old, f_old, thresh_outlier, sn_patch, ind_patch); 
        else
            b_old = b{mpatch};
            f_old = f{mpatch};
            Ypatch = reshape(Ypatch, [], T);
            sn_patch = sn_block(ind_patch);
            [b{mpatch}, f{mpatch}, b0{mpatch}] = fit_svd_model(Ypatch, nb, A_block, C_block, b_old, f_old, thresh_outlier, sn_patch, ind_patch);
        end
        [r, c] = ind2sub([nr_patch, nc_patch], mpatch);
        fprintf('Patch (%2d, %2d) is done. %2d X %2d patches in total. \n', r, c, nr_patch, nc_patch);
        
    end
else
    for mpatch=1:(nr_patch*nc_patch)
        tmp_patch = patch_pos{mpatch};
        tmp_block = block_pos{mpatch};
        
        % find the neurons that are within the block
        mask = zeros(d1, d2);
        mask(tmp_block(1):tmp_block(2), tmp_block(3):tmp_block(4)) = 1;
        A_block = A{mpatch};
        sn_block = sn{mpatch};
        C_block = C{mpatch};
        
        % stop the updating B because A&C doesn't change in this area 
        if isempty(A_block) && (~flag_first)
            [r, c] = ind2sub([nr_patch, nc_patch], mpatch);
            fprintf('Patch (%2d, %2d) is done. %2d X %2d patches in total. \n', r, c, nr_patch, nc_patch);
            continue;
        end
        % use ind_patch to indicate pixels within the patch and only
        % update (W, b0) corresponding to these pixels
        mask(tmp_patch(1):tmp_patch(2), tmp_patch(3):tmp_patch(4)) = 0;
        ind_patch = logical(1-mask(tmp_block(1):tmp_block(2), tmp_block(3):tmp_block(4)));
        
        % pull data
        Ypatch = get_patch_data(mat_data, tmp_patch, frame_range, true);
        if strcmpi(bg_model, 'ring')
            % get the previous estimation
            W_old = W{mpatch};
            Ypatch = reshape(Ypatch, [], T); 
            sn_patch = sn_block(ind_patch); 
            % run regression to get A, C, and W, b0
            [W{mpatch}, b0{mpatch}] = fit_ring_model(Ypatch, A_block, C_block, W_old, thresh_outlier, sn_patch, ind_patch); 
        elseif strcmpi(bg_model, 'nmf')
            b_old = b{mpatch};
            f_old = f{mpatch}; 
            Ypatch = reshape(Ypatch, [], T); 
            sn_patch = sn_block(ind_patch); 
            [b{mpatch}, f{mpatch}] = fit_nmf_model(Ypatch, nb, A_block, C_block, b_old, f_old, thresh_outlier, sn_patch, ind_patch); 
        else
            b_old = b{mpatch};
            f_old = f{mpatch};
            Ypatch = reshape(Ypatch, [], T);
            sn_patch = sn_block(ind_patch);
            [b{mpatch}, f{mpatch}, b0{mpatch}] = fit_svd_model(Ypatch, nb, A_block, C_block, b_old, f_old, thresh_outlier, sn_patch, ind_patch);
        end
        [r, c] = ind2sub([nr_patch, nc_patch], mpatch);
        fprintf('Patch (%2d, %2d) is done. %2d X %2d patches in total. \n', r, c, nr_patch, nc_patch);
        
    end
end
obj.b = b;
obj.f = f;
obj.b0 = b0;
obj.W = W;

%% save the results to log
bg.b = obj.b;
bg.f = obj.f;
bg.b0 = obj.b0;
bg.W = obj.W;
tmp_str = get_date();
tmp_str=strrep(tmp_str, '-', '_');
eval(sprintf('log_data.bg_%s = bg;', tmp_str));
fprintf('Finished updating background using %s model.\n', bg_model);

fprintf(flog, '[%s]\b', get_minute());
fprintf(flog, 'Finished updating background using %s model.\n', bg_model);
fprintf(flog, '\tThe results were saved as intermediate_results.bg_%s\n\n', tmp_str);
fclose(flog);