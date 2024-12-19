function ind_del = cl_viewNeurons(obj, ind, C2, folder_nm)
% Modified version of original with extra views DJS 2024
%
%% view all components and delete components manually. it shows spatial
%   components in the full-frame and zoomed-in view. It also shows temporal
%   components
%% input:
%   ind: vector, indices of components to be displayed, no bigger than the maximum
%       number of neurons
%   C2:  K*T matrix, another temporal component to be displayed together
%       with the esitmated C. usually it is C without deconvolution.

%% Author: Pengcheng Zhou, Carnegie Mellon University, 2016

if ~exist('ind', 'var') || isempty(ind)
    % display all neurons if ind is not specified.
    ind = 1:size(obj.A, 2);
elseif ind==-1
    ind = size(obj.A,2):-1:1;
end
if ~exist('C2', 'var'); C2=[]; end

if exist('folder_nm', 'var')&&(~isempty(folder_nm))
    % create a folder to save images
    save_img = true;
    cur_cd = cd();
    if ~exist(folder_nm, 'dir'); mkdir(folder_nm);
    else
        fprintf('The folder has been created and old results will be overwritten. \n');
    end
    cd(folder_nm);
else
    save_img = false;
end

% obj.delete(sum(obj.A>0, 1)<max(obj.options.min_pixel, 1));

Amask = (obj.A~=0);
ind_trim = false(size(ind));    % indicator of trimming neurons
ind_del = false(size(ind));     % indicator of deleting neurons
ctr = obj.estCenter();      %neuron's center
gSiz = obj.options.gSiz;        % maximum size of a neuron


snr = var(obj.C, 0, 2)./var(obj.C_raw-obj.C, 0, 2);

Coor = obj.get_contours(0.9);
nNeurons = length(ctr);

% time
T = size(obj.C, 2);
t = 1:T;
if ~isnan(obj.Fs)
    t = t/obj.Fs;
    str_xlabel = 'Time (Sec.)';
else
    str_xlabel = 'Frame';
end

%% keep the log information
if ~save_img
    try
        log_file =  obj.P.log_file;
        flog = fopen(log_file, 'a');
        log_data = matfile(obj.P.log_data, 'Writable', true); %#ok<NASGU>
        manual_intervention.before = obj.obj2struct();
        
        fprintf(flog, '[%s]\b', get_minute());
        fprintf(flog, 'Start manual interventions:\n');
    end
end

%% start viewing neurons

points = com(obj.A,size(obj.Cn,1),size(obj.Cn,2));
points = points(:,[2 1]); % (y,x) -> (x,y)


m=1;
while and(m>=1, m<=length(ind))
    fig = findobj('Type','figure','-and','Tag','cl_ViewNeuron');
    if isempty(fig)
        fig = figure;
        fig.Tag = 'cl_ViewNeuron';
        fig.Color = 'w';
        fig.Position = [100, 100, 1024, 512];
    end
    figure(fig);
    clf(fig)



    c = Coor{ind(m)};
    A_ = obj.reshape(obj.A(:, ind(m)).*Amask(:, ind(m)),2);


    %% plot full field
    subplot(221);
    imshow(obj.Cn,[],Colormap=bone);
    % imshow(imadjust(obj.Cn,[.8 1],[],1),Colormap=bone);
    hold on
    plot(points(:,1),points(:,2),'.',Color = [1 .4 .4],MarkerSize=2)
    plot(points(ind(m),1),points(ind(m),2),'.',Color = '#5f99f5',Marker='s',MarkerSize=5,MarkerFaceColor='#5f99f5')
    h = plot(c(1,:),c(2,:),'-',Color='#5f99f5');
    h.LineWidth = 1;
    hold off

    % overlayImage = labeloverlay(obj.Cn, A>0);
    % imshow(overlayImage);
    % imshowpair(obj.Cn,A,ColorChannels="red-cyan")

    % %% full-frame view
    % subplot(232); cla;
    % obj.image(obj.A(:, ind(m)).*Amask(:, ind(m))); %
    % axis equal; axis off;
    



    if ind_del(m)
        sgtitle(sprintf('Neuron %d of %d; SNR=%.3f', ind(m),nNeurons,snr(ind(m))), 'color', 'r');
    else
        sgtitle(sprintf('Neuron %d of %d; SNR=%.3f', ind(m),nNeurons,snr(ind(m))));
    end


    %% zoomed-in view
    subplot(222); cla;
    % obj.image(obj.A(:, ind(m)).*Amask(:, ind(m))); 
    % imagesc(imadjust(obj.Cn,[.5 1],[],1.5));
    imagesc(obj.Cn);
    colormap bone
    hold on
    plot(points(:,1),points(:,2),'.',Color = [1 .4 .4],MarkerSize=2)
    plot(points(ind(m),1),points(ind(m),2),'.',Color = '#5f99f5',Marker='s',MarkerSize=5,MarkerFaceColor='#5f99f5')
    h = plot(c(1,:),c(2,:),'-',Color='#5f99f5');
    h.LineWidth = 1;
    hold off
    axis image
    axis off
    x0 = ctr(ind(m), 2);
    y0 = ctr(ind(m), 1);
    if ~isnan(x0)
        xlim(x0+[-gSiz, gSiz]*2);
        ylim(y0+[-gSiz, gSiz]*2);
    end
    
    %% temporal components
    subplot(2,2,[3 4]);cla;
    if ~isempty(C2)
        plot(t, C2(ind(m), :)*max(obj.A(:, ind(m))), 'linewidth', 2); hold on;
        plot(t, obj.C(ind(m), :)*max(obj.A(:, ind(m))), 'r');
    else
        plot(t, obj.C(ind(m), :)*max(obj.A(:, ind(m))));
    end
    xlim([t(1), t(end)]);
    xlabel(str_xlabel);
    grid on
    yline(0);
    box off

    %% save images
    if save_img
        drawnow();
        saveas(gcf, sprintf('neuron_%d.png', ind(m)));
        m = m+1;
    else
        fprintf('Neuron %d, keep(k, default)/delete(d)/split(s)/trim(t)\n\t/trim cancel(tc)/delete all(da)/backward(b)/end(e):    ', ind(m));
        
        temp = input('', 's');
        if temp=='d'
            ind_del(m) = true;
            m = m+1;
        elseif strcmpi(temp, 'b')
            m = m-1;
        elseif strcmpi(temp, 'da')
            ind_del(m:end) = true;
            break;
        elseif strcmpi(temp, 'k')
            ind_del(m) = false;
            m= m+1;
        elseif strcmpi(temp, 's')
            try
                fprintf('Click and trag on the zoomed in plot to encircle a neuron\n')
                subplot(222);
                temp = imfreehand();
                tmp_ind = temp.createMask();
                tmpA = obj.A(:, ind(m));
                obj.A(:, end+1) = tmpA.*tmp_ind(:);
                obj.C(end+1, :) = obj.C(ind(m), :);
                obj.A(:, ind(m)) = tmpA.*(1-tmp_ind(:));
                obj.S(end+1, :) = obj.S(ind(m), :);
                obj.C_raw(end+1, :) = obj.C_raw(ind(m), :);
                obj.P.kernel_pars(end+1, :) = obj.P.kernel_pars(ind(m), :);
                k_ids = obj.P.k_ids;
                obj.ids(end+1) = k_ids+1;   % assign an neuron id
                obj.tags(end+1) = obj.tags(ind(m));
                obj.P.k_ids = k_ids+1;
                fprintf(flog, '\tSplit %d --> %d + %d\n', obj.ids(ind(m)),obj.ids(ind(m)), k_ids);
            catch
                fprintf('the neuron was not split\n');
            end
        elseif strcmpi(temp, 't')
            try
                fprintf('Click and drag on the zoomed in plot to encircle the neuron\n')
                subplot(222);
                temp = imfreehand();
                tmp_ind = temp.createMask();
                Amask(:, ind(m)) = tmp_ind(:);
                ind_trim(m) = true;
            catch
                fprintf('the neuron was not trimmed\n');
            end
        elseif strcmpi(temp, 'tc')
            Amask(:, ind(m)) = (obj.A(:, ind(m)) > 0);
            ind_trim(m) = false;
        elseif strcmpi(temp, 'e')
            break;
        elseif ~isnan(str2double(temp))
            m = m + floor(str2double(temp));
            m = max(m, 1);
            m = min(m, length(ind));
            fprintf('jump to neuron %d / %d\n', m, length(ind));
        else
            m = m+1;
        end
    end
end
if save_img
    cd(cur_cd);
else
    if ~isempty(ind(ind_trim))
        obj.A(:, ind(ind_trim)) = obj.A(:,ind(ind_trim)).*Amask(:, ind(ind_trim));
        try
            fprintf(flog, '\n\tFollowing neurons were trimmed:\n');
            ids_trimmed = ind(ind_trim);
            for m=1:length(ids_trimmed)
                fprintf(flog, '%2d, ', ids_trimmed(m));
            end
            fprintf(flog, '\n');
        end
    end
    
    if ~isempty(ind(ind_del))
        try
            fprintf(flog, '\tDeleting manually selected neurons:\n');
        end
        obj.delete(ind(ind_del));
    end
    %     obj.Coor = obj.get_contours(0.9);
    
    
    return;
end
try
    fprintf(flog, '[%s]\b', get_minute());
    fprintf(flog, 'Finished the manual intervention.\n');
    fprintf(flog, '[%s]\b', get_minute());
    if obj.options.save_intermediate
        manual_intervention.after = obj.obj2struct(); %#ok<STRNU>
        tmp_str = get_date();
        tmp_str=strrep(tmp_str, '-', '_');
        eval(sprintf('log_data.manual_%s = manual_intervention;', tmp_str));
        
        fprintf(flog, '\tThe results were saved as intermediate_results.manual%s\n\n', tmp_str);
    end
    fclose(flog);
end
end

