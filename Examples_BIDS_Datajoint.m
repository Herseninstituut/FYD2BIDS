%%BIDS - Datajoint Examples ; update or retrieve from various Tables with Datajoint 
%this scripts shows you how to use Datajoint to generate and retrieve metadata

initDJ('roelfsemalab') % credentials to access the database and initialization of Datajoint


%% Structure template to create BIDS channels columns 

% The 'ephys_channels.jsonc' template for electrophysiology defines BIDS spcific fields that 
% should be saved to a channels.tsv file
% you can view the jsonc template in visual studio Code, and edit it
% Comment out fields in the template to create a structure array with fields of your
% choice, (the channel_id and contact_id field are required). 
% Although subject is not required, it's a good idea to register the subject, since channels, contacts and possibly 
% also probes will be specific for a subject. Then you can query the table using
% subject as a key. 
% fields in the template either have '' or [] as default entry, which 
% means they either require a string or a value as an input.

channelsJson = get_json_template('ephys_channels.jsonc');
chan_meta = yaml.loadFile('ephys_channels.yaml');


%EXAMPLE CREATING A CHANNEL ARRAY
% Retrieve the field names (you need these to create a structure array,
% if yor metadata is generated from cell array.
chanFields = fields(channelsJson);

numberOfChannels = 64;
%This creates a cell array with metadata for multiple channels for subject
%L01
chanCell = cell(length(chanFields), numberOfChannels);
for i = 1:numberOfChannels  
    chanCell(:,i) = {'L01', 'BR_01', ['L01_' num2str(i)], num2str(i), 'EXT', 'mV', 30, 'KHz',...
        'Multiunit Activity', 'MUAe', '', 'High Pass, rectification, Low Pass', ...
        '', '', '', num2str(randi(10,1)), 0, 1.0, ...
         -1, 'Chamber screw', ''};
end

%CONVERT to Structure Array 
channelMeta = cell2struct(chanCell, chanFields, 1);

%% Save the records directy to the bids database (please contact us if this doesn't work)
insert(bids.Channels, channelMeta)

%% Retreive channel metadata from the database, selecting by subject
channelMeta  = fetch(bids.Channels & 'subject="L01"', '*'); % or enter all fields separately to retrieve

%this will get all possible columns which you might not want, 
% to restrict the output to the fields you used to generate this metadata
channelMeta = removefields(channelMeta, chanFields); %string cell array of channels
channelMeta = keepfields(channelMeta, chanFields);

%% saving the channel metadata to a tsv file
temp_folder = uigetdir();
ChannelTbl = struct2table(channelMeta);
writetable(ChannelTbl, fullfile(temp_folder, 'channels.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');
 
   
  
%% Structure template to create BIDS contacts columns %%%%%%%%%%%%%%%%%%%%%

contactsJson = get_json_template('ephys_contacts.jsonc');
contactFields = fields(contactsJson);

%Generate contact Metadata structure array from an Excel spreadsheet.
%Make sure they have the correct column names or convert!!!!
contactMeta = readtable("Contacts.xls");

% import from  tsv table    
contactMeta = readtable("contactx.tsv", "FileType","text", 'Delimiter', '\t');

% Save the records to the bids database 
insert(bids.Contacts, contactMeta)

% save the channel metadata to a tsv file
contactTbl = struct2table(contactMeta);
writetable(channelTbl, fullfile(temp_folder, 'channels.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');

   
%% This is a structure template to create BIDS probe columns %%%%%%%%%%%%%%%
% ... note that the probe_id should be unique! ......

probeJson = get_json_template('ephys_probes.jsonc');

%Fields in the template to create a structure array
probeFields = fields(probeJson);

%EXAMPLE Create probes CELL araay
numberOfProbes = 2;
%This creates a cell array with some random metadata for multiple probes
probCell = cell(length(probeFields), numberOfProbes);
for i = 1:numberOfProbes  
    probCell(:,i) = {['Nx_A',num2str(i)], 'L01', 'Neuronexis', '', '', ['L01_' num2str(i)], ...
        'neuronexis-probe', 'silicon', randn(1), randn(1), randn(1), ...
        100, 2000, 2000, 'um', 60, 'left', 'V1', 'Paxinos'};
end

% Convert the cellarray to a structure array and insert in Probes table
probeMeta = cell2struct(probCell, probeFields, 1);
insert(bids.Probes, probeMeta)

probeTbl = struct2table(probeMeta);
writetable(probeTbl, fullfile(temp_folder, 'probes.tsv'), ...
       'FileType', 'text', ...
       'Delimiter', '\t');


%% Show contents of the bids tables
bids.Channels %Show table contents
describe(bids.Channels) % Show table structure

bids.Contacts %Show table contents
describe(bids.Contacts) % Show table structure

bids.Probes %Show table contents
describe(bids.Probes) % Show table structure



%% CAREFULL: Only delete entries in table bids.Probes where the subject is L01
del(bids.Probes & 'subject="L01"') 
