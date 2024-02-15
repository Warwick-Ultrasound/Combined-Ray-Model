function paths = genAllPaths(g, mat, x0, B, flow)
    % From a single ray we get 16 possible paths through the system. This
    % function calculates those 16 and puts each path into a cell array.

    pathKeys = {'LNNL', 'LNNS', 'SNNL', 'SNNS',...
            'LLLL', 'LLLS', 'SLLL', 'SLLS',...
            'LLSL', 'LLSS', 'SLSL', 'SSLS',...
            'LSSL', 'LSSS', 'SSSL', 'SSSS'};
    paths = cell(length(pathKeys),1);
    for ii = 1:length(pathKeys)
        paths{ii} = createPath(g, mat, x0, pathKeys{ii}, B, flow);
    end
end