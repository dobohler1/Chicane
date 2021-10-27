%script to grab data from the archiver during SXRSS chicane study shifts. 

mainPV = {'BEND:UNDS:3510:BACT';
    'BEND:UNDS:3530:BACT';
    'BEND:UNDS:3550:BACT';
    'BEND:UNDS:3570:BACT'};

trimPV = {'BTRM:UNDS:3510:BACT';
    'BTRM:UNDS:3530:BACT';
    'BTRM:UNDS:3550:BACT';
    'BTRM:UNDS:3570:BACT'};

xcorPV = {'XCOR:UNDS:3480:BACT';
'XCOR:UNDS:3580:BACT'; 
'XCOR:UNDS:3680:BACT';
'XCOR:UNDS:3780:BACT';
'XCOR:UNDS:3880:BACT'};

ycorPV = {'YCOR:UNDS:3480:BACT';
'YCOR:UNDS:3580:BACT'; 
'YCOR:UNDS:3680:BACT';
'YCOR:UNDS:3780:BACT';
'YCOR:UNDS:3880:BACT'};

quadPV = {'QUAD:UNDS:3480:BACT';
'QUAD:UNDS:3580:BACT'; 
'QUAD:UNDS:3680:BACT';
'QUAD:UNDS:3780:BACT';
'QUAD:UNDS:3880:BACT'};

bpmxPV = {'BPMS:UNDS:3490:XCUS1H';
    'BPMS:UNDS:3590:XCUS1H';
    'BPMS:UNDS:3690:XCUS1H';
    'BPMS:UNDS:3790:XCUS1H'};


bpmyPV = {'BPMS:UNDS:3490:YCUS1H';
    'BPMS:UNDS:3590:YCUS1H';
    'BPMS:UNDS:3690:YCUS1H';
    'BPMS:UNDS:3790:YCUS1H'};


all =[mainPV;trimPV;xcorPV;ycorPV;quadPV;bpmxPV;bpmyPV];

timeBeg = '10/4/2020 10:32:30';
timeEnd = '10/4/2020 10:34:30';

timeRange ={timeBeg;timeEnd};
[~,~,ut,uv] = history(all, timeRange);
[~,~,~,energy] =history('BEND:DMPH:395:BACT',timeRange);

plot(datenum(ut),uv(:,1))
datetick('x');
xlabel(sprintf('%s to %s',datestr(ut(1)),datestr(ut(end))))
ylabel('BACT')


% here we take the average value of all of the observables at each Bact
id = [1 8; 12 19;22 29;33 40;42 50;52 59;61 68;71 77;80 86;89 96;100 110];
avg=zeros(length(id),31);
for i =1:length(id)
    r1 = id(i,1);
    r2 = id(i,2);
    d = uv(r1:r2,:);
    avg(i,:) = mean(d);
end

%take one of the data example put into bmad and use the solver. Then go
%back and set up 8 universes and find an approach.

%%
ex = avg(5,:);

filename ='SXRSS.tao';
fid = fopen(filename,'w');
formatSpec ='%s\n';
energyStr = ['change ele beginning e_tot @' num2str(mean(energy)) 'e9'];
fprintf(fid,formatSpec, energyStr);

fm_str='set ele sbend::* field_master =T';
kv_str='set ele Vkicker::* field_master =T';
kh_str='set ele Hkicker::* field_master =T';
q_str ='set ele quadrupole::* field_master =T';
fprintf(fid,formatSpec, fm_str);
fprintf(fid,formatSpec, kv_str);
fprintf(fid,formatSpec, kh_str);

%convert kG-m ->T, where L = 0.3636 m
bends = ex(:,1:4)*.1/0.3636;

%set Sbend
BCstr1 = 'change ele BCXSS1 b_field %3.4f\n';
BCstr2 = 'change ele BCXSS2 b_field %3.4f\n';
BCstr3 = 'change ele BCXSS3 b_field %3.4f\n';
BCstr4 = 'change ele BCXSS4 b_field %3.4f\n';

fprintf(fid,BCstr1, bends(1));
fprintf(fid,BCstr2, bends(2));
fprintf(fid,BCstr3, bends(3));
fprintf(fid,BCstr4, bends(4));


xcorbase = {'XCOR:UNDS:3480';
'XCOR:UNDS:3580'; 
'XCOR:UNDS:3680';
'XCOR:UNDS:3780';
'XCOR:UNDS:3880'};

ycorbase = {'YCOR:UNDS:3480';
'YCOR:UNDS:3580'; 
'YCOR:UNDS:3680';
'YCOR:UNDS:3780';
'YCOR:UNDS:3880'};

xcorEpics = model_nameConvert(xcorbase,'MAD');
ycorEpics = model_nameConvert(ycorbase,'MAD');

corEpics =[xcorEpics;ycorEpics];

corStr = 'change ele %s bl_kick %3.6f\n';

for j = 1:length(corEpics)
    val = ex(1,8+j)*0.1;
    fprintf(fid, corStr,corEpics{j},val);
end
   

quadbase = {'QUAD:UNDS:3480';
'QUAD:UNDS:3580'; 
'QUAD:UNDS:3680';
'QUAD:UNDS:3780';
'QUAD:UNDS:3880'};

quadEpics = model_nameConvert(quadbase,'MAD');

quadStr = 'change ele %s b1_gradient %3.6f\n';

%convert kG ->T/m,/ where L = 0.084 m
quads = ex(:,19:23)*.1/0.084;


for j = 1:length(quadEpics)
    val = ex(1,18+j)*0.1;
    fprintf(fid, quadStr,quadEpics{j},val);
end


bpmbase = {'BPMS:UNDS:3490';
    'BPMS:UNDS:3590';
    'BPMS:UNDS:3690';
    'BPMS:UNDS:3790'};

bpmEpics = model_nameConvert(bpmbase,'MAD');

bpmStrX = 'set dat orbit.profx[%d]|meas =%7.7f\n';
bpmStrY = 'set dat orbit.profy[%d]|meas =%7.7f\n';
bpmX = ex(end-7:end-4);
bpmY = ex(end-3:end);

for j = 1:length(bpmEpics)
    
    fprintf(fid, bpmStrX,j,bpmX(j));
    fprintf(fid, bpmStrY,j,bpmY(j));
end


trimbase = {'BTRM:UNDS:3510';
    'BTRM:UNDS:3530';
    'BTRM:UNDS:3550';
    'BTRM:UNDS:3570'};

trimEpics = model_nameConvert(trimbase,'MAD');

trimStr = 'set var trim[%d]|meas = %3.6f\n';
%need to convert this into the T currently in Amps...divide by ptrim and
%convert
trim = ex(5:8)/68.5*.1;

for j = 1:length(trimEpics)
    fprintf(fid, trimStr,j,trim(j));
end


sc_str ='scale';
var_str ='use var *';
dat_str ='set dat loss|meas =0';
gl_str = 'set global n_opti_loops=30';


fprintf(fid,formatSpec, sc_str);
fprintf(fid,formatSpec, var_str);
fprintf(fid,formatSpec, dat_str);
fprintf(fid,formatSpec, gl_str);

fclose(fid);