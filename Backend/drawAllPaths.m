function drawAllPaths(paths)
    % Takes the full set of calculated paths and draws the received ones
    % using drawPath.
    for ii = 1:size(paths, 1)
        for jj = 1:size(paths, 2)
            if paths{ii,jj}.detected
                drawPath(paths{ii,jj});
            end
        end
    end
end