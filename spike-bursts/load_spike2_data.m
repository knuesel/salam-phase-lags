function data = load_spike2_data(basename, chan_type, chan_positions)
% LOAD_SPIKE2_DATA    Load .mat files exported by Spike2
%
% LOAD_SPIKE2_DATA(BASENAME, CHAN_TYPE, CHAN_POSITIONS)
%
%    Loads the specified file, keeping the selected channels based on a
%    heuristics on the channel names.
%
% INPUTS:
%
%    BASENAME:      name of the .mat file to import (without .mat extension)
%
%    CHAN_TYPE:     type of channels to keep for processing, one of:
%                   'ipsi' (for ipsilateral channels)
%                   'contra' (for contralateral channels)
%                   'limbs' (for limb channels)
%
%    CHAN_POSITIONS: channel positions to keep (empty means keep all)
%                    (the position is extracted from the channel name)
%
% OUTPUT: an array of channel structs, each with the following fields:
%
%   index:    the index of the channel in the Spike2 dataset
%   positon:  the channel position extracted from its name (e.g. ventral root number)
%   values:   the channel data
%   interval: the sampling interval in seconds
%   length:   the size of the data

    spike2 = load([basename '.mat']);
    spike2_fields = fieldnames(spike2);
    
    % Note: e.g. iVR_ and iVR\  must be listed before iVR
    ipsi_channels = {'iVR_', 'iVR ', 'iVR', 'i_vr', 'VR_', 'VR ', 'VR', 'Sgt', 'h_vr', 'ipsiVR', 'ipsi VR', 'i_sg'};
    contra_channels = {'cVR', 'c_vr', 'coVR ', 'CoVR', 'coVR', 'c_sg'};
    limb_channels = {'SP_', 'SP ', 'sp_', 'sp ', 'SP', 'sp'};
    
    if strcmp(chan_type, 'ipsi')
        prefixes = ipsi_channels;
    elseif strcmp(chan_type, 'contra')
        prefixes = contra_channels;
    elseif strcmp(chan_type, 'limbs')
        prefixes = limb_channels;
    else
        error(['Invalid channel type ' chan_type])
    end
    
    data = load_channels(spike2, prefixes, chan_positions);


function channels = load_channels(spike2, prefixes, keep)
    spike2_fields = fieldnames(spike2);
    channels = struct('index', {}, 'position', {}, 'values', {}, 'interval', {}, 'length', {});
    
    for i = 1:length(spike2_fields)
        field_name = spike2_fields{i};
        channel_name = spike2.(field_name).title;
        disp(['Processing channel ' channel_name]);
        
        for prefix = prefixes
            if length(channel_name) >= length(prefix{1}) && strcmp(channel_name(1:length(prefix{1})), prefix{1})
                
                position = str2num(channel_name(length(prefix{1}) + 1:end));
                
                if isempty(keep) || ~isempty(find(keep == position))
                    n = length(channels) + 1;
                    channels(n).index = i;
                    channels(n).position = position;
                    channels(n).values = spike2.(field_name).values;
                    channels(n).interval = spike2.(field_name).interval;
                    channels(n).length = length(channels(n).values);
                end
                
                break;
            end
        end
    end

    [~, order] = sort([channels.position]);
    channels = channels(order);
