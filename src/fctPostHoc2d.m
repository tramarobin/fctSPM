function []=fctPostHoc2d(nEffects,indicesEffects,maps1d,dimensions,modalitiesAll,typeEffectsAll,eNames,contourColor,savedir,multiIterations,IT,xlab,ylab,Fs,ylimits,nx,ny,colorbarLabel,imageResolution,displayContour,limitMeanMaps,xlimits,anovaEffects,maximalIT,doAllInteractions,dashedColor,transparency,lineWidth,imageFontSize,imageSize,colorMap,colorMapDiff,diffRatio,relativeRatio,alphaT,nT,linestyle)
close all
if isempty(nx)
    nx=5;
end
if isempty(ny)
    ny=4;
end
set(0, 'DefaultFigureVisible', 'off');
savedir=[savedir '/Post hoc/'];

%% T-TEST 1 EFFECT = MAIN EFFECT
if nEffects==1
    
    createSavedir2d(savedir)
    
    loop=0;
    for i=1:max(indicesEffects)
        loop=loop+1;
        combi{loop}=i;
    end
    nCombi=size(combi,2);
    
    positionDiffPlot=[];
    positionSPMPlot=[];
    
    if isempty(imageSize)
        f1=figure('Units', 'Pixels', 'OuterPosition', [0, 0, 720, 480],'visible','off');
    elseif max(size(imageSize))==1
        f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize, imageSize],'visible','off');
    else
        f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize(1), imageSize(2)],'visible','off');
    end
    
    for i=1:nCombi
        
        % means
        meansData=reshape(mean(maps1d(indicesEffects==combi{i}(1),:)),dimensions(1),dimensions(2));
        stdData=reshape(std(maps1d(indicesEffects==combi{i}(1),:)),dimensions(1),dimensions(2));
        posthoc.data.names{i}=[char(modalitiesAll{1}(combi{i}(1)))];
        posthoc.data.meanContinuum{i}=meansData;
        posthoc.data.sdContinuum{i}=stdData;
        positionDiffPlot=[positionDiffPlot,(i-1)*nCombi+i+1:(i-1)*nCombi+i+1+nCombi-i-1];
        positionSPMPlot=[positionSPMPlot,(i)*nCombi+i:nCombi:nCombi.^2-1];
        
        % full plot mean
        displayMeanMaps(meansData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
        title(char(modalitiesAll{1}(combi{i}(1))))
        print('-dtiff',imageResolution,[savedir '/' verifSaveName(char(modalitiesAll{1}(combi{i}(1))))])
        savefig([savedir '/FIG/' verifSaveName(char(modalitiesAll{1}(combi{i}(1))))])
        close
        
        % full plot sd
        displayMeanMaps(stdData,Fs,xlab,ylab,ylimits,nx,ny,[],xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
        title(char(modalitiesAll{1}(combi{i}(1))))
        print('-dtiff',imageResolution,[savedir '/SD/' verifSaveName(char(modalitiesAll{1}(combi{i}(1))))])
        savefig([savedir '/FIG/SD/' verifSaveName(char(modalitiesAll{1}(combi{i}(1))))])
        close
        
        % subplot
        set(0, 'currentfigure', f1);
        subplot(nCombi,nCombi,nCombi*(i-1)+i);
        displayMeanMaps_sub(meansData,Fs,limitMeanMaps,colorMap)
        title(char(modalitiesAll{1}(combi{i}(1))))
        
    end
    
    loop=0;
    for i=1:size(combi,2)
        for j=1:size(combi,2)
            if i<j
                loop=loop+1;
                Comp{loop}=[i j];
            end
        end
    end
    
    nComp=size(Comp,2);
    if ~isempty(nT)
        alphaOriginal=0.05/nT;
    else
        alphaOriginal=alphaT/nComp;
    end
    
    for comp=1:nComp
        
        for i=1:2
            % comparison + name
            DATA{i}=maps1d(indicesEffects==combi{Comp{comp}(i)}(1),:);
        end
        posthoc.differences.names{1,comp}=char([modalitiesAll{1}{combi{Comp{comp}(1)}(1)} ' - ' modalitiesAll{1}{combi{Comp{comp}(2)}(1)}]);
        
        if typeEffectsAll>0
            
            % differences
            differencesData=reshape(mean(DATA{1}-DATA{2}),dimensions(1),dimensions(2));
            relativeDifferencesData=reshape(100*mean((DATA{1}-DATA{2})./DATA{2}),dimensions(1),dimensions(2));
            
            posthoc.differences.continuum{1,comp}=differencesData;
            posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
            
            Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
            posthoc.tTests.type{comp}='paired';
            [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
            
        else
            
            % differences
            differencesData=reshape(mean(DATA{1})-mean(DATA{2}),dimensions(1),dimensions(2));
            relativeDifferencesData=reshape(100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2}),dimensions(1),dimensions(2));
            
            posthoc.differences.continuum{1,comp}=differencesData;
            posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
            
            Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
            posthoc.tTests.type{comp}='independant';
            [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
        end
        
        posthoc.differences.ES{comp}=reshape(posthoc.differences.ES{comp},dimensions(1),dimensions(2));
        posthoc.differences.ESsd{comp}=reshape(posthoc.differences.ESsd{comp},dimensions(1),dimensions(2));
        
        % inference
        posthoc.tTests.names=posthoc.differences.names;
        [posthoc.tTests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
        posthoc.tTests.alphaOriginal{comp}=alphaOriginal;
        posthoc.tTests.alpha{comp}=alpha;
        posthoc.tTests.nIterations{comp}=iterations;
        Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1),'two_tailed',logical(1));
        posthoc.tTests.maxIterations{comp}=Ttest_inf.nPermUnique;
        posthoc.tTests.Tthreshold{comp}=Ttest_inf.zstar;
        posthoc.tTests.Tcontinuum{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
        mapLogical=abs(posthoc.tTests.Tcontinuum{1,comp})>=posthoc.tTests.Tthreshold{comp};
        posthoc.tTests.Tsignificant{1,comp}=zeros(dimensions(1),dimensions(2));
        posthoc.tTests.Tsignificant{1,comp}(anovaEffects{1})=mapLogical(anovaEffects{1});
        posthoc.tTests.contourSignificant{1,comp}=zeros(dimensions(1),dimensions(2));
        posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1))=abs(posthoc.tTests.Tcontinuum{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1)));
        datanoAnova=abs(posthoc.tTests.Tcontinuum{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==0)));
        datanoAnova(find(datanoAnova>=posthoc.tTests.Tthreshold{comp}))=posthoc.tTests.Tthreshold{comp}-0.01*posthoc.tTests.Tthreshold{comp};
        posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==0))=datanoAnova;
        posthoc.tTests.contourSignificant{1,comp}=reshape(posthoc.tTests.contourSignificant{1,comp},dimensions(1),dimensions(2));
        
        % full plot of difference
        displayDiffMaps(differencesData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMapDiff,diffRatio)
        if displayContour
            dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
        end
        title(posthoc.differences.names{1,comp})
        print('-dtiff',imageResolution,[savedir '/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
        savefig([savedir '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
        close
        
        displayRelativeDiffMaps(relativeDifferencesData,Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff,relativeRatio)
        if displayContour
            dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
        end
        title(posthoc.differences.names{1,comp})
        print('-dtiff',imageResolution,[savedir '/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
        savefig([savedir '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
        close
        
        % subplot of differences
        set(0, 'currentfigure', f1);
        ax=subplot(nCombi,nCombi,positionDiffPlot(comp));
        displayDiffMaps_sub(differencesData,Fs,limitMeanMaps,diffRatio,colorMapDiff,ax)
        if displayContour
            dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,1,linestyle)
        end
        
        % full plot of spm analysis
        displayTtest(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},[],Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff)
        if displayContour
            dispContour(abs(posthoc.tTests.Tcontinuum{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
        end
        title(posthoc.differences.names{1,comp})
        print('-dtiff',imageResolution,[savedir '/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
        savefig([savedir '/FIG/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
        close
        
        % subplot of spm analysis
        set(0, 'currentfigure', f1);
        ax=subplot(nCombi,nCombi,positionSPMPlot(comp));
        displayTtest_sub(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},Fs,colorMapDiff,ax)
        
        %     cohen's d
        displayMapsES(posthoc.differences.ES{comp},Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMap)
        title(posthoc.differences.names{1,comp})
        if displayContour
            dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
        end
        print('-dtiff',imageResolution,[savedir '/ES/' verifSaveName(posthoc.differences.names{1,comp})])
        savefig([savedir '/FIG/ES/' verifSaveName(posthoc.differences.names{1,comp})])
        close
        
    end
    
    % save
    set(0, 'currentfigure', f1);
    print('-dtiff',imageResolution,[savedir '/' verifSaveName(eNames{1})])
    savefig([savedir '/FIG/' verifSaveName(eNames{1})])
    close
    
    save([savedir 'posthoc'], 'posthoc')
    clear Comp combi isPlot posthoc
    
end

%% T-TESTS 2 EFFECTS - 1 FIXED =  2 MAIN EFFECTS
if nEffects==2
    % choose fixed effect and main effect (tested)
    eff=[1;2];
    for eff_fixed=1:size(eff,1)
        fixedEffect=eff(eff_fixed,:);
        mainEffect=1:size(eff,1);
        mainEffect(fixedEffect)=[];
        
        createSavedir2d([savedir eNames{mainEffect(1)}])
        
        loop=0;
        for i=1:max(indicesEffects(:,mainEffect(1)))
            loop=loop+1;
            combi{loop}=i;
        end
        nCombi=size(combi,2);
        
        positionDiffPlot=[];
        positionSPMPlot=[];
        if isempty(imageSize)
            f1=figure('Units', 'Pixels', 'OuterPosition', [0, 0, 720, 480],'visible','off');
        elseif max(size(imageSize))==1
            f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize, imageSize],'visible','off');
        else
            f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize(1), imageSize(2)],'visible','off');
        end
        for i=1:nCombi
            % means
            meansData=reshape(mean(maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1),:)),dimensions(1),dimensions(2));
            stdData=reshape(std(maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1),:)),dimensions(1),dimensions(2));
            posthoc.data.names{i}=[char(modalitiesAll{mainEffect(1)}(combi{i}(1)))];
            posthoc.data.meanContinuum{i}=meansData;
            posthoc.data.sdContinuum{i}=stdData;
            positionDiffPlot=[positionDiffPlot,(i-1)*nCombi+i+1:(i-1)*nCombi+i+1+nCombi-i-1];
            positionSPMPlot=[positionSPMPlot,(i)*nCombi+i:nCombi:nCombi.^2-1];
            
            % full plot of mean
            displayMeanMaps(meansData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
            title(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            close
            
            % full plot of sd
            displayMeanMaps(stdData,Fs,xlab,ylab,ylimits,nx,ny,[],xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
            title(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/SD/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/SD/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            close
            
            % subplot
            set(0, 'currentfigure', f1);
            subplot(nCombi,nCombi,nCombi*(i-1)+i)
            displayMeanMaps_sub(meansData,Fs,limitMeanMaps,colorMap)
            title(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))
            
        end
        
        loop=0;
        for i=1:size(combi,2)
            for j=1:size(combi,2)
                if i<j
                    loop=loop+1;
                    Comp{loop}=[i j];
                end
            end
        end
        
        nComp=size(Comp,2);
        if ~isempty(nT)
            alphaOriginal=0.05/nT;
        else
            alphaOriginal=alphaT/nComp;
        end
        
        for comp=1:nComp
            alphaOriginal=alphaT/nComp;
            for i=1:2
                % comparison + name
                DATA{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{Comp{comp}(i)}(1),:);
            end
            posthoc.differences.names{1,comp}=char([modalitiesAll{mainEffect(1)}{combi{Comp{comp}(1)}(1)} ' - ' modalitiesAll{mainEffect(1)}{combi{Comp{comp}(2)}(1)}]);
            
            % t-test
            if typeEffectsAll(mainEffect)==1
                
                % differences
                differencesData=reshape(mean(DATA{1}-DATA{2}),dimensions(1),dimensions(2));
                relativeDifferencesData=reshape(100*mean((DATA{1}-DATA{2})./DATA{2}),dimensions(1),dimensions(2));
                
                posthoc.differences.continuum{1,comp}=differencesData;
                posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                
                Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                posthoc.tTests.type{comp}='paired';
                [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
                
            else
                
                % differences
                differencesData=reshape(mean(DATA{1})-mean(DATA{2}),dimensions(1),dimensions(2));
                relativeDifferencesData=reshape(100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2}),dimensions(1),dimensions(2));
                
                posthoc.differences.continuum{1,comp}=differencesData;
                posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                
                Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                posthoc.tTests.type{comp}='independant';
                [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
            end
            
            posthoc.differences.ES{comp}=reshape(posthoc.differences.ES{comp},dimensions(1),dimensions(2));
            posthoc.differences.ESsd{comp}=reshape(posthoc.differences.ESsd{comp},dimensions(1),dimensions(2));
            
            % inference
            [posthoc.tTests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
            posthoc.tTests.alphaOriginal{comp}=alphaOriginal;
            posthoc.tTests.alpha{comp}=alpha;
            posthoc.tTests.nIterations{comp}=iterations;
            Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1),'two_tailed',logical(1));
            posthoc.tTests.maxIterations{comp}=Ttest_inf.nPermUnique;
            posthoc.tTests.Tthreshold{comp}=Ttest_inf.zstar;
            posthoc.tTests.Tsignificant{1,comp}=zeros(dimensions(1),dimensions(2));
            posthoc.tTests.Tcontinuum{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
            mapLogical=abs(posthoc.tTests.Tcontinuum{1,comp})>=posthoc.tTests.Tthreshold{comp};
            posthoc.tTests.Tsignificant{1,comp}(anovaEffects{mainEffect})=mapLogical(anovaEffects{mainEffect});
            posthoc.tTests.contourSignificant{1,comp}=zeros(dimensions(1),dimensions(2));
            posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1))=abs(posthoc.tTests.Tcontinuum{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1)));
            datanoAnova=abs(posthoc.tTests.Tcontinuum{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==0)));
            datanoAnova(find(datanoAnova>=posthoc.tTests.Tthreshold{comp}))=posthoc.tTests.Tthreshold{comp}-0.01*posthoc.tTests.Tthreshold{comp};
            posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==0))=datanoAnova;
            posthoc.tTests.contourSignificant{1,comp}=reshape(posthoc.tTests.contourSignificant{1,comp},dimensions(1),dimensions(2));
            
            % full plot of differences
            displayDiffMaps(differencesData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMapDiff,diffRatio)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            displayRelativeDiffMaps(relativeDifferencesData,Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff,relativeRatio)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
            close
            
            % subplot of differences
            set(0, 'currentfigure', f1);
            ax=subplot(nCombi,nCombi,positionDiffPlot(comp));
            displayDiffMaps_sub(differencesData,Fs,limitMeanMaps,diffRatio,colorMapDiff,ax)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,1,linestyle)
            end
            
            %  full plot of spm analysis
            displayTtest(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},[],Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff)
            if displayContour
                dispContour(abs(posthoc.tTests.Tcontinuum{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            %     cohen's
            displayMapsES(posthoc.differences.ES{comp},Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMap)
            title(posthoc.differences.names{1,comp})
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/ES/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/ES/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            % subplot of spm analysis
            set(0, 'currentfigure', f1);
            ax=subplot(nCombi,nCombi,positionSPMPlot(comp));
            displayTtest_sub(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},Fs,colorMapDiff,ax)
            
        end
        
        % save
        set(0, 'currentfigure', f1);
        print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/' verifSaveName(eNames{mainEffect(1)})])
        savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/' verifSaveName(eNames{mainEffect(1)})])
        close
        
        mainForInteraction{mainEffect}=posthoc.tTests.Tsignificant;
        save([savedir verifSaveName(eNames{mainEffect(1)}) '/posthoc'], 'posthoc')
        clear Comp combi isPlot posthoc
        
    end
    
end
%% T-TESTS 3 EFFECTS - 2 FIXED = 3 MAIN EFFECTS
if nEffects==3
    
    % choose fixed effects and main effect (tested)
    eff=[1 2; 1 3; 2 3];
    for eff_fixed=1:size(eff,1)
        fixedEffect=eff(eff_fixed,:);
        mainEffect=1:size(eff,1);
        mainEffect(fixedEffect)=[];
        
        createSavedir2d([savedir verifSaveName(eNames{mainEffect(1)})])
        
        loop=0;
        for i=1:max(indicesEffects(:,mainEffect(1)))
            loop=loop+1;
            combi{loop}=i;
        end
        nCombi=size(combi,2);
        
        positionDiffPlot=[];
        positionSPMPlot=[];
        
        if isempty(imageSize)
            f1=figure('Units', 'Pixels', 'OuterPosition', [0, 0, 720, 480],'visible','off');
        elseif max(size(imageSize))==1
            f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize, imageSize],'visible','off');
        else
            f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize(1), imageSize(2)],'visible','off');
        end
        
        for i=1:nCombi
            
            % means
            meansData=reshape(mean(maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1),:)),dimensions(1),dimensions(2));
            stdData=reshape(std(maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1),:)),dimensions(1),dimensions(2));
            posthoc.data.names{i}=[char(modalitiesAll{mainEffect(1)}(combi{i}(1)))];
            posthoc.data.meanContinuum{i}=meansData;
            posthoc.data.sdContinuum{i}=stdData;
            positionDiffPlot=[positionDiffPlot,(i-1)*nCombi+i+1:(i-1)*nCombi+i+1+nCombi-i-1];
            positionSPMPlot=[positionSPMPlot,(i)*nCombi+i:nCombi:nCombi.^2-1];
            
            % full plot of means
            displayMeanMaps(meansData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
            title(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            close
            
            % full plot of sd
            displayMeanMaps(stdData,Fs,xlab,ylab,ylimits,nx,ny,[],xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
            title([char(modalitiesAll{mainEffect(1)}(combi{i}(1)))])
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/SD/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/SD/' verifSaveName(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))])
            close
            
            
            % subplot of means
            set(0, 'currentfigure', f1);
            subplot(nCombi,nCombi,nCombi*(i-1)+i)
            displayMeanMaps_sub(meansData,Fs,limitMeanMaps,colorMap)
            title(char(modalitiesAll{mainEffect(1)}(combi{i}(1))))
            
        end
        
        loop=0;
        for i=1:size(combi,2)
            for j=1:size(combi,2)
                if i<j
                    loop=loop+1;
                    Comp{loop}=[i j];
                end
            end
        end
        
        nComp=size(Comp,2);
        if ~isempty(nT)
            alphaOriginal=0.05/nT;
        else
            alphaOriginal=alphaT/nComp;
        end
        
        for comp=1:nComp
            alphaOriginal=alphaT/nComp;
            
            for i=1:2
                % comparison + name
                DATA{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{Comp{comp}(i)}(1),:);
            end
            posthoc.differences.names{1,comp}=char([modalitiesAll{mainEffect(1)}{combi{Comp{comp}(1)}(1)} ' - ' modalitiesAll{mainEffect(1)}{combi{Comp{comp}(2)}(1)}]);
            
            
            % t-test
            if typeEffectsAll(mainEffect)==1
                differencesData=reshape(mean(DATA{1}-DATA{2}),dimensions(1),dimensions(2));
                relativeDifferencesData=reshape(100*mean((DATA{1}-DATA{2})./DATA{2}),dimensions(1),dimensions(2));
                
                posthoc.differences.continuum{1,comp}=differencesData;
                posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                
                Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                posthoc.tTests.type{comp}='paired';
                [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
            else
                differencesData=reshape(mean(DATA{1})-mean(DATA{2}),dimensions(1),dimensions(2));
                relativeDifferencesData=reshape(100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2}),dimensions(1),dimensions(2));
                
                posthoc.differences.continuum{1,comp}=differencesData;
                posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                
                Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                posthoc.tTests.type{comp}='independant';
                [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
            end
            
            posthoc.differences.ES{comp}=reshape(posthoc.differences.ES{comp},dimensions(1),dimensions(2));
            posthoc.differences.ESsd{comp}=reshape(posthoc.differences.ESsd{comp},dimensions(1),dimensions(2));
            
            % inference
            [posthoc.tTests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
            posthoc.tTests.alphaOriginal{comp}=alphaOriginal;
            posthoc.tTests.alpha{comp}=alpha;
            posthoc.tTests.nIterations{comp}=iterations;
            Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1),'two_tailed',logical(1));
            posthoc.tTests.maxIterations{comp}=Ttest_inf.nPermUnique;
            posthoc.tTests.Tthreshold{comp}=Ttest_inf.zstar;
            posthoc.tTests.Tsignificant{1,comp}=zeros(dimensions(1),dimensions(2));
            posthoc.tTests.Tcontinuum{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
            mapLogical=abs(posthoc.tTests.Tcontinuum{1,comp})>=posthoc.tTests.Tthreshold{comp};
            posthoc.tTests.Tsignificant{1,comp}(anovaEffects{mainEffect})=mapLogical(anovaEffects{mainEffect});
            posthoc.tTests.contourSignificant{1,comp}=zeros(dimensions(1),dimensions(2));
            posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1))=abs(posthoc.tTests.Tcontinuum{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1)));
            datanoAnova=abs(posthoc.tTests.Tcontinuum{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==0)));
            datanoAnova(find(datanoAnova>=posthoc.tTests.Tthreshold{comp}))=posthoc.tTests.Tthreshold{comp}-0.01*posthoc.tTests.Tthreshold{comp};
            posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==0))=datanoAnova;
            posthoc.tTests.contourSignificant{1,comp}=reshape(posthoc.tTests.contourSignificant{1,comp},dimensions(1),dimensions(2));
            
            % full plot of differences
            displayDiffMaps(differencesData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMapDiff,diffRatio)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            displayRelativeDiffMaps(relativeDifferencesData,Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff,relativeRatio)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
            close
            
            % subplot of differences
            set(0, 'currentfigure', f1);
            ax=subplot(nCombi,nCombi,positionDiffPlot(comp));
            displayDiffMaps_sub(differencesData,Fs,limitMeanMaps,diffRatio,colorMapDiff,ax)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,1,linestyle)
            end
            
            %  full plot of spm analysis
            displayTtest(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},[],Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff)
            if displayContour
                dispContour(abs(posthoc.tTests.Tcontinuum{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            %     cohen's d
            displayMapsES(posthoc.differences.ES{comp},Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMap)
            title(posthoc.differences.names{1,comp})
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/ES/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/ES/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            % subplot of spm analysis
            set(0, 'currentfigure', f1);
            ax=subplot(nCombi,nCombi,positionSPMPlot(comp));
            displayTtest_sub(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},Fs,colorMapDiff,ax)
            
        end
        
        % save
        set(0, 'currentfigure', f1);
        print('-dtiff',imageResolution,[savedir verifSaveName(eNames{mainEffect(1)}) '/' verifSaveName(eNames{mainEffect(1)})])
        savefig([savedir verifSaveName(eNames{mainEffect(1)}) '/FIG/' verifSaveName(eNames{mainEffect(1)})])
        close
        
        mainForInteraction{mainEffect}=posthoc.tTests.Tsignificant;
        save([savedir verifSaveName(eNames{mainEffect(1)}) '/posthoc'], 'posthoc')
        clear Comp combi isPlot posthoc
        
    end
end
%% T-TESTS 3 EFFECTS - 1 FIXED = INTERACTION
if nEffects==3
    
    % chose fixed effect and the interation effects
    for eff_fixed=1:3
        fixedEffect=eff_fixed;
        mainEffect=1:3;
        mainEffect(eff_fixed)=[];
        anovaFixedCorr=[3 2 1];
        
        if max(anovaEffects{3+anovaFixedCorr(fixedEffect)})==1 | doAllInteractions==1
            
            for e=1:2
                createSavedir2dInt([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(e)})])
            end
            mkdir([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/SD']);
            mkdir([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/FIG/SD']);
            
            loop=0;
            for i=1:max(indicesEffects(:,mainEffect(1)))
                for j=1:max(indicesEffects(:,mainEffect(2)))
                    loop=loop+1;
                    combi{loop}=[i j];
                end
            end
            nCombi=size(combi,2);
            
            positionDiffPlot=[];
            positionSPMPlot=[];
            
            
            if isempty(imageSize)
                f1=figure('Units', 'Pixels', 'OuterPosition', [0, 0, 720, 480],'visible','off');
            elseif max(size(imageSize))==1
                f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize, imageSize],'visible','off');
            else
                f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize(1), imageSize(2)],'visible','off');
            end
            
            for i=1:nCombi
                
                % means
                meansData=reshape(mean(maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1) & indicesEffects(:,mainEffect(2))==combi{i}(2),:)),dimensions(1),dimensions(2));
                stdData=reshape(std(maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1) & indicesEffects(:,mainEffect(2))==combi{i}(2),:)),dimensions(1),dimensions(2));
                posthoc.data.names{i}=[char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' x ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))];
                posthoc.data.meanContinuum{i}=meansData;
                posthoc.data.sdContinuum{i}=stdData;
                positionDiffPlot=[positionDiffPlot,(i-1)*nCombi+i+1:(i-1)*nCombi+i+1+nCombi-i-1];
                positionSPMPlot=[positionSPMPlot,(i)*nCombi+i:nCombi:nCombi.^2-1];
                
                % full plot of means
                displayMeanMaps(meansData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
                title([char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' \cap ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))])
                print('-dtiff',imageResolution,[savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName([char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' x ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))])])
                savefig([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/FIG/' verifSaveName([char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' x ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))])])
                close
                
                % full plot of std
                displayMeanMaps(stdData,Fs,xlab,ylab,ylimits,nx,ny,[],xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
                title([char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' \cap ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))])
                print('-dtiff',imageResolution,[savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/SD/' verifSaveName([char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' x ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))])])
                savefig([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/FIG/SD/' verifSaveName([char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' x ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))])])
                close
                
                % subplot of means
                set(0, 'currentfigure', f1);
                subplot(nCombi,nCombi,nCombi*(i-1)+i)
                displayMeanMaps_sub(meansData,Fs,limitMeanMaps,colorMap)
                title([char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' \cap ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))])
                
            end
            
            loop=0;
            loopForPlot=0;
            for i=1:size(combi,2)
                for j=1:size(combi,2)
                    if i<j
                        loopForPlot=loopForPlot+1;
                        if max(size(find(combi{i}~=combi{j})))==1
                            loop=loop+1;
                            Comp{loop}=[i j];
                            isPlot(loopForPlot)=1;
                            testedEffect{loop}=find(combi{i}~=combi{j});
                        end
                    end
                end
            end
            
            nComp=size(Comp,2);
            if ~isempty(nT)
                alphaOriginal=0.05/nT;
            else
                alphaOriginal=alphaT/nComp;
            end
            
            isPlot=find(isPlot==1);
            
            for comp=1:nComp
                
                alphaOriginal=alphaT/nComp;
                
                for i=1:2
                    % comparison + name
                    DATA{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{Comp{comp}(i)}(1) & indicesEffects(:,mainEffect(2))==combi{Comp{comp}(i)}(2),:);
                    intForInteractions{anovaFixedCorr(eff_fixed)}.comp{comp}(i,:)=combi{Comp{comp}(i)};
                end
                [eFixed,eTested,modalFixed,modalTested]=findWhichTitle([combi{Comp{comp}(1)};combi{Comp{comp}(2)}]);
                posthoc.differences.names{1,comp}=char([modalitiesAll{mainEffect(eFixed)}{modalFixed} ' (' modalitiesAll{mainEffect(eTested)}{modalTested(1)} ' - ' modalitiesAll{mainEffect(eTested)}{modalTested(2)} ')']);
                
                
                % t-test
                if typeEffectsAll(mainEffect(eTested))==1
                    differencesData=reshape(mean(DATA{1}-DATA{2}),dimensions(1),dimensions(2));
                    relativeDifferencesData=reshape(100*mean((DATA{1}-DATA{2})./DATA{2}),dimensions(1),dimensions(2));
                    
                    posthoc.differences.continuum{1,comp}=differencesData;
                    posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                    
                    Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                    posthoc.tTests.type{comp}='paired';
                    [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
                else
                    differencesData=reshape(mean(DATA{1})-mean(DATA{2}),dimensions(1),dimensions(2));
                    relativeDifferencesData=reshape(100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2}),dimensions(1),dimensions(2));
                    
                    posthoc.differences.continuum{1,comp}=differencesData;
                    posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                    
                    Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                    posthoc.tTests.type{comp}='independant';
                    [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
                end
                
                posthoc.differences.ES{comp}=reshape(posthoc.differences.ES{comp},dimensions(1),dimensions(2));
                posthoc.differences.ESsd{comp}=reshape(posthoc.differences.ESsd{comp},dimensions(1),dimensions(2));
                
                % inference
                [posthoc.tTests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
                posthoc.tTests.alphaOriginal{comp}=alphaOriginal;
                posthoc.tTests.alpha{comp}=alpha;
                posthoc.tTests.nIterations{comp}=iterations;
                Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1),'two_tailed',logical(1));
                posthoc.tTests.maxIterations{comp}=Ttest_inf.nPermUnique;
                posthoc.tTests.Tthreshold{comp}=Ttest_inf.zstar;
                posthoc.tTests.Tsignificant{1,comp}=zeros(dimensions(1),dimensions(2));
                posthoc.tTests.Tcontinuum{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
                mapLogical=abs(posthoc.tTests.Tcontinuum{1,comp})>=posthoc.tTests.Tthreshold{comp};
                effectCorr=anovaEffects{3+anovaFixedCorr(fixedEffect)}(:);
                posthoc.tTests.Tsignificant{1,comp}(effectCorr)=mapLogical(effectCorr);
                indiceMain=findWhichMain(modalitiesAll{mainEffect(testedEffect{comp})},combi{Comp{comp}(1)}(testedEffect{comp}),combi{Comp{comp}(2)}(testedEffect{comp}));
                tMainEffect=abs(mainForInteraction{mainEffect(testedEffect{comp})}{indiceMain})>0;
                tMainEffect(effectCorr==1)=0;
                realEffect{comp}=reshape(max([tMainEffect(:)';posthoc.tTests.Tsignificant{1,comp}(:)']),dimensions(1),dimensions(2));
                posthoc.tTests.Tsignificant{1,comp}=realEffect{comp};
                posthoc.tTests.contourSignificant{1,comp}=zeros(dimensions(1),dimensions(2));
                posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1))=1.1*posthoc.tTests.Tthreshold{comp};
                
                % full plot of differences
                displayDiffMaps(differencesData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMapDiff,diffRatio)
                if displayContour
                    dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
                end
                title(posthoc.differences.names{1,comp})
                print('-dtiff',imageResolution,[savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
                savefig([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
                close
                
                displayRelativeDiffMaps(relativeDifferencesData,Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff,relativeRatio)
                if displayContour
                    dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
                end
                title(posthoc.differences.names{1,comp})
                print('-dtiff',imageResolution,[savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
                savefig([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
                close
                
                
                % subplot of differences
                set(0, 'currentfigure', f1);
                ax=subplot(nCombi,nCombi,positionDiffPlot(isPlot(comp)));
                displayDiffMaps_sub(differencesData,Fs,limitMeanMaps,diffRatio,colorMapDiff,ax)
                if displayContour
                    dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,1,linestyle)
                end
                
                %  full plot of spm analysis
                displayTtest(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},[],Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff)
                if displayContour
                    dispContour(abs(posthoc.tTests.Tcontinuum{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
                end
                title(posthoc.differences.names{1,comp})
                print('-dtiff',imageResolution,[savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
                savefig([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/FIG/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
                close
                
                %     cohen's d
                displayMapsES(posthoc.differences.ES{comp},Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMap)
                title(posthoc.differences.names{1,comp})
                if displayContour
                    dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
                end
                print('-dtiff',imageResolution,[savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/ES/' verifSaveName(posthoc.differences.names{1,comp})])
                savefig([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/' verifSaveName(eNames{mainEffect(eTested)}) '/FIG/ES/' verifSaveName(posthoc.differences.names{1,comp})])
                close
                
                % subplot of spm analysis
                set(0, 'currentfigure', f1);
                ax=subplot(nCombi,nCombi,positionSPMPlot(isPlot(comp)));
                displayTtest_sub(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},Fs,colorMapDiff,ax)
                
            end
            
            % save
            set(0, 'currentfigure', f1);
            print('-dtiff',imageResolution,[savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}])   '/' verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}])])
            savefig([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}])   '/FIG/' verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}])])
            close
            
            intForInteractions{anovaFixedCorr(eff_fixed)}.t=realEffect;
            save([savedir verifSaveName([eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]) '/posthoc'], 'posthoc')
            clear Comp combi isPlot realEffect posthoc
            
        end
    end
end

%% T-TESTS ALL INTERACTIONS (ANOVA 2 and 3)
if nEffects>1
    
    if nEffects==2
        isInteraction=max(anovaEffects{3});
        savedir2=[verifSaveName([eNames{1} ' x ' eNames{2}])  '/'] ;
        if isInteraction==1 | doAllInteractions==1
            createSavedir2dInt([savedir savedir2 verifSaveName(eNames{1})])
            createSavedir2dInt([savedir savedir2 verifSaveName(eNames{2})])
        end
        figname =[verifSaveName([eNames{1} ' x ' eNames{2}])];
    elseif nEffects==3
        isInteraction=max(anovaEffects{7});
        savedir2=[verifSaveName([eNames{1} ' x ' eNames{2} ' x ' eNames{3}]) '/'];
        if isInteraction==1 | doAllInteractions==1
            createSavedir2dInt([savedir savedir2 verifSaveName(eNames{1})])
            createSavedir2dInt([savedir savedir2 verifSaveName(eNames{2})])
            createSavedir2dInt([savedir savedir2 verifSaveName(eNames{3})])
        end
        figname=[verifSaveName([eNames{1} ' x ' eNames{2} ' x ' eNames{3}])];
    end
    mkdir([savedir savedir2 '/SD']);
    mkdir([savedir savedir2 '/FIG/SD']);
    
    if isInteraction==1 | doAllInteractions==1
        
        loop=0;
        positionDiffPlot=[];
        positionSPMPlot=[];
        
        
        if isempty(imageSize)
            f1=figure('Units', 'Pixels', 'OuterPosition', [0, 0, 720, 480],'visible','off');
        elseif max(size(imageSize))==1
            f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize, imageSize],'visible','off');
        else
            f1=figure('Units', 'Centimeter', 'OuterPosition', [0, 0, imageSize(1), imageSize(2)],'visible','off');
        end
        % number of combinations + plot of each
        if nEffects==2
            
            for i=1:max(indicesEffects(:,1))
                for j=1:max(indicesEffects(:,2))
                    loop=loop+1;
                    combi{loop}=[i j];
                end
            end
            nCombi=size(combi,2);
            
            for i=1:nCombi
                
                if size(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2),:),1)>1
                    meansData=reshape(mean(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2),:)),dimensions(1),dimensions(2));
                    stdData=reshape(std(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2),:)),dimensions(1),dimensions(2));
                    
                    % full plot of sd
                    displayMeanMaps(stdData,Fs,xlab,ylab,ylimits,nx,ny,[],xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
                    title([char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2)))])
                    print('-dtiff',imageResolution,[savedir savedir2 '/SD/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2)))])])
                    savefig([savedir savedir2 '/FIG/SD/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2)))])])
                    close
                else
                    meansData=reshape(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2),:),dimensions(1),dimensions(2));
                end
                positionDiffPlot=[positionDiffPlot,(i-1)*nCombi+i+1:(i-1)*nCombi+i+1+nCombi-i-1];
                positionSPMPlot=[positionSPMPlot,(i)*nCombi+i:nCombi:nCombi.^2-1];
                
                posthoc.data.names{i}=[char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2)))];
                posthoc.data.meanContinuum{i}=meansData;
                posthoc.data.sdContinuum{i}=stdData;
                
                % full plot of means
                displayMeanMaps(meansData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
                title([char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2)))])
                print('-dtiff',imageResolution,[savedir savedir2 '/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2)))])])
                savefig([savedir savedir2 '/FIG/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2)))])])
                close
                
                % subplot of means
                set(0, 'currentfigure', f1);
                subplot(nCombi,nCombi,nCombi*(i-1)+i)
                displayMeanMaps_sub(meansData,Fs,limitMeanMaps,colorMap)
                title([char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2)))])
                
            end
            
        elseif nEffects==3
            
            for i=1:max(indicesEffects(:,1))
                for j=1:max(indicesEffects(:,2))
                    for k=1:max(indicesEffects(:,3))
                        loop=loop+1;
                        combi{loop}=[i j k];
                    end
                end
            end
            nCombi=size(combi,2);
            
            for i=1:nCombi
                
                if size(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2) & indicesEffects(:,3)==combi{i}(3),:),1)>1
                    meansData=reshape(mean(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2) & indicesEffects(:,3)==combi{i}(3),:)),dimensions(1),dimensions(2));
                    stdData=reshape(std(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2) & indicesEffects(:,3)==combi{i}(3),:)),dimensions(1),dimensions(2));
                    % full plot std
                    displayMeanMaps(stdData,Fs,xlab,ylab,ylimits,nx,ny,[],xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
                    title([char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2))) ' \cap '  char(modalitiesAll{3}(combi{i}(3)))])
                    print('-dtiff',imageResolution,[savedir savedir2 '/SD/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2))) ' x '  char(modalitiesAll{3}(combi{i}(3)))])])
                    savefig([savedir savedir2 '/FIG/SD/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2))) ' x '  char(modalitiesAll{3}(combi{i}(3)))])])
                    close
                else
                    meansData=reshape(maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2) & indicesEffects(:,3)==combi{i}(3),:),dimensions(1),dimensions(2));
                end
                positionDiffPlot=[positionDiffPlot,(i-1)*nCombi+i+1:(i-1)*nCombi+i+1+nCombi-i-1];
                positionSPMPlot=[positionSPMPlot,(i)*nCombi+i:nCombi:nCombi.^2-1];
                posthoc.data.names{i}=[char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2))) ' x '  char(modalitiesAll{3}(combi{i}(3)))];
                posthoc.data.meanContinuum{i}=meansData;
                posthoc.data.sdContinuum{i}=stdData;
                
                % full plot of means
                displayMeanMaps(meansData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMap)
                title([char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2))) ' \cap '  char(modalitiesAll{3}(combi{i}(3)))])
                print('-dtiff',imageResolution,[savedir savedir2 '/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2))) ' x '  char(modalitiesAll{3}(combi{i}(3)))])])
                savefig([savedir savedir2 '/FIG/' verifSaveName([char(modalitiesAll{1}(combi{i}(1))) ' x ' char(modalitiesAll{2}(combi{i}(2))) ' x '  char(modalitiesAll{3}(combi{i}(3)))])])
                close
                
                % subplot of means
                set(0, 'currentfigure', f1);
                subplot(nCombi,nCombi,nCombi*(i-1)+i)
                displayMeanMaps_sub(meansData,Fs,limitMeanMaps,colorMap)
                title([char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2))) ' \cap '  char(modalitiesAll{3}(combi{i}(3)))])
                
            end
            
        end
        
        % number of comparisons + plot of each
        loop=0;
        loopForPlot=0;
        for i=1:size(combi,2)
            for j=1:size(combi,2)
                if i<j
                    loopForPlot=loopForPlot+1;
                    if max(size(find(combi{i}~=combi{j})))==1
                        loop=loop+1;
                        Comp{loop}=[i j];
                        isPlot(loopForPlot)=1;
                        testedEffect{loop}=find(combi{i}~=combi{j});
                    end
                end
            end
        end
        
        nComp=size(Comp,2);
        if ~isempty(nT)
            alphaOriginal=0.05/nT;
        else
            alphaOriginal=alphaT/nComp;
        end
        
        isPlot=find(isPlot==1);
        
        
        for comp=1:nComp
            
            
            for i=1:2
                % comparison + name
                if nEffects==2
                    DATA{i}=maps1d(indicesEffects(:,1)==combi{Comp{comp}(i)}(1) & indicesEffects(:,2)==combi{Comp{comp}(i)}(2),:);
                    [eFixed,eTested,modalFixed,modalTested]=findWhichTitle([combi{Comp{comp}(1)};combi{Comp{comp}(2)}]);
                    posthoc.differences.names{1,comp}=char([modalitiesAll{eFixed}{modalFixed} ' (' modalitiesAll{eTested}{modalTested(1)} ' - ' modalitiesAll{eTested}{modalTested(2)} ')']);
                elseif nEffects==3
                    DATA{i}=maps1d(indicesEffects(:,1)==combi{Comp{comp}(i)}(1) & indicesEffects(:,2)==combi{Comp{comp}(i)}(2) & indicesEffects(:,3)==combi{Comp{comp}(i)}(3),:);
                    [eFixed,eTested,modalFixed,modalTested]=findWhichTitle([combi{Comp{comp}(1)};combi{Comp{comp}(2)}]);
                    posthoc.differences.names{1,comp}=char([modalitiesAll{eFixed(1)}{modalFixed(1)} ' x ' modalitiesAll{eFixed(2)}{modalFixed(2)} ' (' modalitiesAll{eTested}{modalTested(1)} ' - ' modalitiesAll{eTested}{modalTested(2)} ')']);
                end
            end
            
            % t-test
            if typeEffectsAll(eTested)==1
                differencesData=reshape(mean(DATA{1}-DATA{2}),dimensions(1),dimensions(2));
                relativeDifferencesData=reshape(100*mean((DATA{1}-DATA{2})./DATA{2}),dimensions(1),dimensions(2));
                
                posthoc.differences.continuum{1,comp}=differencesData;
                posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                
                Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                posthoc.tTests.type{comp}='paired';
                [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
            else
                differencesData=reshape(mean(DATA{1})-mean(DATA{2}),dimensions(1),dimensions(2));
                relativeDifferencesData=reshape(100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2}),dimensions(1),dimensions(2));
                
                posthoc.differences.continuum{1,comp}=differencesData;
                posthoc.differences.continuumRelative{1,comp}=relativeDifferencesData;
                
                Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                posthoc.tTests.type{comp}='independant';
                [posthoc.differences.ES{comp},posthoc.differences.ESsd{comp}]=esCalculation(DATA);
            end
            
            posthoc.differences.ES{comp}=reshape(posthoc.differences.ES{comp},dimensions(1),dimensions(2));
            posthoc.differences.ESsd{comp}=reshape(posthoc.differences.ESsd{comp},dimensions(1),dimensions(2));
            
            % inference
            [posthoc.tTests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
            posthoc.tTests.alphaOriginal{comp}=alphaOriginal;
            posthoc.tTests.alpha{comp}=alpha;
            posthoc.tTests.nIterations{comp}=iterations;
            Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1),'two_tailed',logical(1));
            posthoc.tTests.maxIterations{comp}=Ttest_inf.nPermUnique;
            posthoc.tTests.Tthreshold{comp}=Ttest_inf.zstar;
            posthoc.tTests.Tcontinuum{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
            posthoc.tTests.Tsignificant{1,comp}=zeros(dimensions(1),dimensions(2));
            mapLogical=abs(posthoc.tTests.Tcontinuum{1,comp})>=posthoc.tTests.Tthreshold{comp}; % significant clusters
            if nEffects==2
                % main effect
                indiceMain=findWhichMain(modalitiesAll{testedEffect{comp}},combi{Comp{comp}(1)}(testedEffect{comp}),combi{Comp{comp}(2)}(testedEffect{comp}));
                tMainEffect=abs(mainForInteraction{testedEffect{comp}}{indiceMain})>0;
                % interaction effect
                effectCorr=anovaEffects{3}(:);
            else
                intLocations=[4 5;4 6;5 6]-3;
                for interactions=1:2
                    indiceInteraction=findWhichInteraction(intForInteractions{intLocations(testedEffect{comp},interactions)}.comp,combi(Comp{comp}),interactions,testedEffect{comp});
                    tInteractionEffect{interactions}=intForInteractions{intLocations(testedEffect{comp},interactions)}.t{indiceInteraction}(:);
                end
                effectCorr=anovaEffects{7};
            end
            
            posthoc.tTests.Tsignificant{1,comp}(effectCorr)=mapLogical(effectCorr);
            
            if nEffects==2
                tMainEffect(effectCorr==1)=0;
                realEffect{comp}=reshape(max([tMainEffect(:)';posthoc.tTests.Tsignificant{1,comp}(:)']),dimensions(1),dimensions(2));
            else
                for interactions=1:2
                    tInteractionEffect{interactions}(effectCorr==1)=0;
                end
                realEffect{comp}=reshape(max([tInteractionEffect{1}';tInteractionEffect{2}';posthoc.tTests.Tsignificant{1,comp}(:)']),dimensions(1),dimensions(2));
            end
            posthoc.tTests.Tsignificant{1,comp}=realEffect{comp};
            posthoc.tTests.contourSignificant{1,comp}=zeros(dimensions(1),dimensions(2));
            posthoc.tTests.contourSignificant{1,comp}(find(posthoc.tTests.Tsignificant{1,comp}==1))=1.1*posthoc.tTests.Tthreshold{comp};
            
            %  full plot of spm analysis
            displayTtest(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},[],Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff)
            if displayContour
                dispContour(abs(posthoc.tTests.Tcontinuum{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}})  '/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}})  '/FIG/SPM/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            % full plot of differences
            displayDiffMaps(differencesData,Fs,xlab,ylab,ylimits,nx,ny,limitMeanMaps,xlimits,imageFontSize,imageSize,colorbarLabel,colorMapDiff,diffRatio)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}})  '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            displayRelativeDiffMaps(relativeDifferencesData,Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMapDiff,relativeRatio)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            title(posthoc.differences.names{1,comp})
            print('-dtiff',imageResolution,[savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}}) '/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
            savefig([savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}})  '/FIG/DIFF/' verifSaveName(posthoc.differences.names{1,comp}) ' %'])
            close
            
            %     cohen's d
            displayMapsES(posthoc.differences.ES{comp},Fs,xlab,ylab,ylimits,nx,ny,xlimits,imageFontSize,imageSize,colorMap)
            title(posthoc.differences.names{1,comp})
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,lineWidth,linestyle)
            end
            print('-dtiff',imageResolution,[savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}})  '/ES/' verifSaveName(posthoc.differences.names{1,comp})])
            savefig([savedir savedir2 '/' verifSaveName(eNames{testedEffect{comp}})  '/FIG/ES/' verifSaveName(posthoc.differences.names{1,comp})])
            close
            
            % subplot of spm analysis
            set(0, 'currentfigure', f1);
            ax=subplot(nCombi,nCombi,positionSPMPlot(isPlot(comp)));
            displayTtest_sub(posthoc.tTests.Tcontinuum{1,comp},posthoc.tTests.Tthreshold{comp},Fs,colorMapDiff,ax)
            
            % subplot of differences
            set(0, 'currentfigure', f1);
            ax=subplot(nCombi,nCombi,positionDiffPlot(isPlot(comp)));
            displayDiffMaps_sub(differencesData,Fs,limitMeanMaps,diffRatio,colorMapDiff,ax)
            if displayContour
                dispContour(abs(posthoc.tTests.contourSignificant{1,comp}),posthoc.tTests.Tthreshold{comp},contourColor,dashedColor,transparency,1,linestyle)
            end
            
        end
        
        % save
        set(0, 'currentfigure', f1);
        print('-dtiff',imageResolution,[savedir savedir2 '/' figname])
        savefig([savedir savedir2 '/FIG/' figname])
        close
        
        save([savedir figname '/posthoc'], 'posthoc')
        clear Comp combi isPlot posthoc
        
    end
    
end

end
