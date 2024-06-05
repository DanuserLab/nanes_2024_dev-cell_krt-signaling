function [] = bnLocalMotionEstimation(MD, Cind, params, dirs, varargin)

    ip = inputParser;
    addParameter(ip, 'preproc', @(x) x, @(x) true);
    parse(ip, varargin{:});
    preproc = ip.Results.preproc;

    if exist([dirs.mfDataOrig 'C' num2str(Cind) '_001_mf.mat'],'file') && params.always   
        % unix(sprintf('rm %s',[dirs.mfDataOrig '*.mat']));
        delete([dirs.mfDataOrig 'C' num2str(Cind) '*.mat']);    
    end

    if exist([dirs.mfData 'C' num2str(Cind) '_001_mf.mat'],'file') && params.always    
        % unix(sprintf('rm %s',[dirs.mfData '*.mat']));    
        delete([dirs.mfData 'C' num2str(Cind) '*.mat']);
    end

    for t = 1 : params.nTime
        mfFname = [dirs.mfData 'C' num2str(Cind) '_' sprintf('%03d',t) '_mf.mat'];

        if exist(mfFname,'file') && ~params.always
            fprintf(sprintf('Skipping motion estimation for frame %d as it has already been done!\n',t));
            continue;
        end

        fprintf(sprintf('Motion estimation for frame %d\n',t));
        
        % Now loading from MovieData objects
        I0 = MD.getChannel(Cind).loadImage(t, 1);
        I1 = MD.getChannel(Cind).loadImage(t+params.frameJump,1);
        if ~params.isDx
            I0 = rot90(I0);
            I1 = rot90(I1);
        end
        I0 = preproc(I0);
        I1 = preproc(I1);

        [dydx, dys, dxs, scores] = blockMatching(I0, I1, params.patchSize,params.searchRadiusInPixels,true(size(I0))); % block width, search radius,
    
        if params.fixGlobalMotion
            meanDxs = mean(dxs(~isnan(dxs)));
            meanDys = mean(dxs(~isnan(dxs)));
            if abs(meanDxs) > 0.5
                dxs = dxs - meanDxs;
            end
            if abs(meanDys) > 0.5
                dys = dys - meanDys;
            end
        end
        
        save(mfFname,'dxs', 'dys','scores');

    end

end
