function vdfs = load_neighbors_vdf(output_dir,baseFileName,P)
%neighbors Returns term used in gradient of vdf objective and vdfs 
%          of coefficients neighboring point (i,j)

% Get list of possible neighbors
[row,col] = ind2sub(P.sampleDims,P.img);

rows = [row-1;
        row+1; 
        row;
        row];
cols = [col;
        col; 
        col-1;
        col+1];

% Remove invalid neighbors
keep = (rows >= 1).*(rows <=P.sampleDims(1)).*...
       (cols >= 1).*(cols <=P.sampleDims(2));
neighbor_imgs = [rows(keep==1),cols(keep==1)];

%Get contributions and vdfs from neighbors

vdfs = {}; 
for i = 1:size(neighbor_imgs,1)
    n_img = sub2ind(P.sampleDims,neighbor_imgs(i,1),neighbor_imgs(i,2));
    load_file = fullfile(output_dir,sprintf(baseFileName,P.set,n_img));
    fileData = load(load_file);
    x_hat_var = fileData.x_hat;
    vdf = squeeze(sum(sum(x_hat_var,1),2))/sum(x_hat_var(:));
    vdfs{i} = vdf;
end


