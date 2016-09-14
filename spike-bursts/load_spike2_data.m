function data = load_spike2_data(basename, side, roots)

    spike2 = load([basename '.mat']);
    spike2_fields = fieldnames(spike2);
    
    % Note: e.g. iVR_ and iVR\  must be listed before iVR
    ipsi_roots = {'iVR_', 'iVR ', 'iVR', 'i_vr', 'VR_', 'VR ', 'VR', 'Sgt', 'h_vr', 'ipsiVR', 'ipsi VR', 'i_sg'};
    contra_roots = {'cVR', 'c_vr', 'coVR ', 'CoVR', 'coVR', 'c_sg'};
    limb_roots = {'SP_', 'SP ', 'sp_', 'sp ', 'SP', 'sp'};
    
    if strcmp(side, 'ipsi')
        prefixes = ipsi_roots;
    elseif strcmp(side, 'ipsi+limbs')
        prefixes = [ipsi_roots limb_roots];
    % elseif strcmp(side, 'ipsi+contra')
    %     prefixes = [ipsi_roots contra_roots];
    else
        prefixes = contra_roots;
    end
    
    data = load_channels(spike2, prefixes, roots);


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
