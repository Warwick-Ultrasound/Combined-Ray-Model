function paths = genAllPaths(g, mat, x0, B, flow, varargin)
    % From a single ray we get 16 possible paths through the system. This
    % function calculates those 16 and puts each path into a cell array.
    % The optional input is for the ray to be reflected from the normal if
    % desired for the edges of the beam.

    pathKeys = {'LNNL', 'LNNS', 'SNNL', 'SNNS',...
            'LLLL', 'LLLS', 'SLLL', 'SLLS',...
            'LLSL', 'LLSS', 'SLSL', 'SSLS',...
            'LSSL', 'LSSS', 'SSSL', 'SSSS'};
    paths = cell(length(pathKeys),1);
    for ii = 1:length(pathKeys)
        if isempty(varargin)
            paths{ii} = createPath(g, mat, x0, pathKeys{ii}, B, flow);
        else
            paths{ii} = createPath(g, mat, x0, pathKeys{ii}, B, flow, varargin{1}, varargin{2});
        end
    end
end