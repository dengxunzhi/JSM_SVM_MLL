
 %%%%Author: Qishuo GAO email:  qishuo.gao@student.unsw.edu.au
clc
close all
clear all

load Indian_pines_corrected;
load Indian_pines_gt;

img=indian_pines_corrected;
gt=indian_pines_gt;
Patch=7;
scale_num = length(Patch);   
no_classes=16;
no_bands=200;
im = img;
Neigh = Patch*Patch;   
dim = floor(Patch/2);  

scalemap = 1: Patch*Patch;
scalemap = reshape(scalemap,[Patch Patch]);
xx = dim+1;
yy = dim+1;

%Gerate the neighbors for each scale
scale_index = {};

index_temp = scalemap((xx-dim):(xx+dim),(yy-dim):(yy+dim));
index_vec = index_temp(:)'; 
scale_index{1} = index_vec;

img_extend = {};
img_extend = padarray(im,[dim dim],'symmetric'  );    

[I_row,I_line,I_high] = size(im);
im1 = reshape(im,[I_row*I_line,I_high]);
im1 = im1';


K = no_classes;

Train_Label = [];
Train_index = [];
for ii = 1: no_classes
   index_ii =  find(indian_pines_gt == ii);
   class_ii = ones(length(index_ii),1)* ii;
   Train_Label = [Train_Label class_ii'];
   Train_index = [Train_index index_ii'];   
end

K = max(Train_Label);
% Select the number of training samples for each class
Train_Num = [20 50 50 50 50 50 10 50 10 50 50 50 21 50 50 20];%for indian pines
tr_lab = [];
tt_lab = [];
tr_dat = [];

% Create the Training and Testing set with randomly sampling 3-D Dataset and its correponding index
Index_train = {};
Index_test = {};
for i = 1: K
    W_Class_Index = find(Train_Label == i);
    Random_num = randperm(length(W_Class_Index));
    Random_Index = W_Class_Index(Random_num);
    Tr_Index = Random_Index(1:Train_Num(i));
    Index_train{i} = Train_index(Tr_Index);
    Tt_Index{i} = Random_Index(Train_Num(i)+1 :end);
    Index_test{i} = Train_index(Tt_Index{i});
    tr_ltemp = ones(Train_Num(i),1)'* i;
    tr_lab = [tr_lab tr_ltemp];
    tr_Class_DAT = im1(:,Train_index(Tr_Index));
    tr_dat = cat(2,tr_dat,tr_Class_DAT);
end

% Normalizing the training data with 2-norm
tr_dat        =    tr_dat./ repmat(sqrt(sum(tr_dat.*tr_dat)),[size(tr_dat,1) 1]); 

classids       =    unique(tr_lab);
NumClass       =    length(classids);
tt_ID          =    [];


%% Calculate the propabalities for all samples
gap=zeros(21025,K);
pp=zeros(I_row,I_line,K);
prob=zeros(I_row,I_line,K);

for i = 1:21025

    tt_dat = {};
    tt_ID_temp = [];
    [X,Y]=ind2sub(size(indian_pines_gt),i);
    X_new = X+dim;
    Y_new = Y+dim;         
    X_range = [X_new-dim : X_new+dim];
    Y_range = [Y_new-dim : Y_new+dim];
    tt_Class_DAT_temp = img_extend(X_range,Y_range,:);
    [r,l,h]=size(tt_Class_DAT_temp);
    tt_Class_DAT_temp = reshape(tt_Class_DAT_temp,[r*l,h]);
    tt_Class_DAT = tt_Class_DAT_temp';
    tt_Class_DAT =  tt_Class_DAT./ repmat(sqrt(sum(tt_Class_DAT.*tt_Class_DAT)),[size(tt_Class_DAT,1) 1]); 
    tt_dat{1} = tt_Class_DAT(:,scale_index{1});      
           
%%   Calculate the sparse matix       
    sparstiy_matrix = SOMP(tr_dat,tt_dat,2, 1,tr_lab );   
%%   Determined the label of a test sample
    [tt_ID1,gap(i,:)] = label_new(NumClass, 1,sparstiy_matrix , tr_dat, tt_dat, classids, tr_lab);
    tt_ID_temp  =  [tt_ID_temp tt_ID1];           
    tt_ID = [tt_ID tt_ID_temp];
    pp(X,Y,:)=gap(i,:)';
    lamda=sum(pp(X,Y,:),3);
    for t=1:K
        prob(X,Y,t)=1/(lamda*pp(X,Y,t));
    end
end



%% Calculate the accuracy for JSM

prob=reshape(prob,145*145,K);
prob=prob';
save prob_ip.mat prob
[a b]=max(prob);
result=reshape(b,145,145);% the result map for JSM
[JSM_acc] = ComputeClassificationAccuracy(result,indian_pines_gt)

