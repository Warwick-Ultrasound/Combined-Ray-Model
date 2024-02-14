function [pathKeys, pkpk2] = pathAnalyser(paths, display)
    % Searches through the paths created to see which modes the
    % contributions come from. Want the total peak to peak from different
    % pathKeys plotted as a bar chart.
    %
    % Inputs:
    %   paths: cell array of path structs
    %   display: bool determines whether or not figures are plotted
    %
    % Outputs:
    %   pathKeys: categorical of possible pathKeys in correct order
    %   pkpk2: pk-pk amplitude of summed waveforms for each pathKey


    % extract possible pathKeys from paths
    col = paths(:,1); % one source ray, all resultant rays. Contains all poss pathKeys
    pathKeys = cell(size(col));
    for ii = 1:length(col)
        pathKeys{ii} = col{ii}.pathKey;
    end
    temp = pathKeys; % save order
    pathKeys = categorical(pathKeys); % convert to categorical
    pathKeys = reordercats(pathKeys, temp); % revert to original order
    clear temp; % clear temporary array saved for ordering
    
    % one row for each pathKey => add up contributions
    pkpk = zeros(size(pathKeys));
    for ii = 1:size(paths,1) % cycle through rows
        for jj = 1:size(paths,2) % going across the row
            if paths{ii,jj}.detected
                pkpk(ii) = pkpk(ii) + paths{ii,jj}.pk_pk;
            end
        end
    end

    % plot bar graph
    if display
        figure;
        bar(pathKeys, pkpk);
        xlabel('Path Taken');
        ylabel('Sum of pk-pk of contributions /arb.');
        title('Sum of pk-pk of each contribution', 'Does not take into account the phase');
    end

    % repeat, this time summing the signals and taking the peak-to-peak of
    % that. This accounts for phase differences and
    % constructive/destructive interference.
    pathSignals = cell(size(pathKeys)); % one signal per pathKey
    pkpk2 = nan(size(pathKeys));
    for ii = 1:length(pathKeys)

        % construct signal
        pathSignals{ii} = zeros(size(paths{ii,jj}.burst));
        for jj = 1:size(paths, 2) % all paths with same pathKey
            if paths{ii,jj}.detected
                pathSignals{ii} = pathSignals{ii} + paths{ii,jj}.burst;
            end
        end

        % measure pk-pk amplitude
        pkpk2(ii) = max(pathSignals{ii}) - min(pathSignals{ii});
    end

    % plot bar graph
    if display
        figure;
        bar(pathKeys, pkpk2);
        xlabel('Path Taken');
        ylabel('pk-pk of summed contributions /arb.');
        title('pk-pk of summed signal', 'Does take into account the phase');
    end
end