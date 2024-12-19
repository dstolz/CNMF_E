%%
fig = findobj('type','figure','-and','tag','neuron_mosaic');
if isempty(fig)
    fig = figure(Tag = 'neuron_mosaic',Color='w');
end
figure(fig);
clf(fig);

gSiz = neuron.options.gSiz;        % maximum size of a neuron
ctr = neuron.estCenter();      %neuron's center
Amask = (neuron.A~=0);

nNeurons = size(neuron.A,2);

M = nan(gSiz*2,gSiz*2,nNeurons);
[Mr,Mc,Mn] = size(M);
for i = 1:nNeurons

    x0 = ctr(i,2);
    y0 = ctr(i,1);


    xi = floor(x0-gSiz);
    yi = floor(y0-gSiz);

    xi = xi:xi+gSiz*2-1;
    yi = yi:yi+gSiz*2-1;

    
    
    A = neuron.reshape(neuron.A(:,i).*Amask(:,i),2);  
    
    xi(xi<1|xi>size(A,2)) = [];
    yi(yi<1|yi>size(A,1)) = [];
    
    A = A(yi,xi);
    
    px = (Mc-length(xi))/2;
    py = (Mr-length(yi))/2;
    A = padarray(A,[py px],nan,"symmetric");

    A = A ./ max(A);
    M(:,:,i) = A;
end

montage(M);
colormap bone