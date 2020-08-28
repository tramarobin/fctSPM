function []=fctPostHoc1d(nEffects,indicesEffects,maps1d,dimensions,modalitiesAll,typeEffectsAll,eNames,savedir,multiIterations,IT,xlab,ylab,Fs,imageResolution,IC,ylimits,nx,ny,xlimits,anovaEffects,maximalIT,colorLine,doAllInteractions,imageFontSize,imageSize,alphaT,nT,transparancy1D,ratioSPM,yLimitES,spmPos,aovColor)
close all
set(0, 'DefaultFigureVisible', 'off');
savedir=[savedir '\Post hoc\'];

%% T-TEST 1 EFFECT = MAIN EFFECT
if nEffects==1
    
    if max(anovaEffects{1})==1 | doAllInteractions==1
        
        createSavedir(savedir)
        
        loop=0;
        for i=1:max(indicesEffects)
            loop=loop+1;
            combi{loop}=i;
        end
        nCombi=size(combi,2);
        
        legendPlot=[];
        for i=1:nCombi
            
            meansData{i}=maps1d(indicesEffects==combi{i}(1),:);
            legendPlot=[legendPlot,{char(modalitiesAll{1}(combi{i}(1)))}];
            namesConditions{i}=[char(modalitiesAll{1}(combi{i}(1)))];
            
        end
        
        % full plot of means
        colorPlot=chooseColor(colorLine,1);
        plotmean(meansData,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits)
        legend(legendPlot,'Location','eastoutside','box','off')
        print('-dtiff',imageResolution,[savedir eNames{1} '.tiff'])
        savefig([savedir '\FIG\' eNames{1}])
        close
        
        mapsConditions=meansData;
        clear meansData
        
        loop=0;
        for i=1:nCombi
            for j=1:nCombi
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
                namesDifferences{comp,i}=[char(modalitiesAll{1}(combi{Comp{comp}(i)}(1)))];
            end
            
            % t-test
            if typeEffectsAll>0
                differencesData{1}=DATA{1}-DATA{2};
                relativeDifferencesData{1}=100*(DATA{1}-DATA{2})./DATA{2};
                
                Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                testTtests.name{comp}='paired';
                [ES{comp},ESsd{comp}]=esCalculation(DATA);
                
            else
                
                % differences
                differencesData{1}=mean(DATA{1})-mean(DATA{2});
                relativeDifferencesData{1}=100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2});
                
                Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                testTtests.name{comp}='independant';
                [ES{comp},ESsd{comp}]=esCalculation(DATA);
            end
            
            mapsDifferences{1,comp}=differencesData{1};
            mapsDifferences{2,comp}=relativeDifferencesData{1};
            
            % inference
            [testTtests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
            testTtests.alphaOriginal{comp}=alphaOriginal;
            testTtests.alpha{comp}=alpha;
            testTtests.nIterations{comp}=iterations;
            Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1));
            Tthreshold{comp}=Ttest_inf.zstar;
            clustersT{comp}=Ttest_inf.clusters;
            mapsT{2,comp}=zeros(dimensions(1),dimensions(2));
            mapsT{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
            mapLogical=abs(mapsT{1,comp})>=Tthreshold{comp};
            mapsT{2,comp}(anovaEffects{1})=mapLogical(anovaEffects{1});
            
            plotmean(differencesData,IC,xlab,ylab,Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
            legend([namesDifferences{comp,1} ' - ' namesDifferences{comp,2}],'Location','eastoutside','box','off')
            print('-dtiff',imageResolution,[savedir 'DIFF\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ').tiff'])
            savefig([savedir '\FIG\DIFF\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ')'])
            close
            
            plotmean(relativeDifferencesData,IC,xlab,'Differences (%)',Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
            legend([namesDifferences{comp,1} ' - ' namesDifferences{comp,2}],'Location','eastoutside','box','off')
            print('-dtiff',imageResolution,[savedir 'DIFF\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ') %.tiff'])
            savefig([savedir '\FIG\DIFF\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ') %'])
            close
            
            % plot of spm analysis
            displayTtest(mapsT{1,comp},Tthreshold{comp},mapsT{2,comp},Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,transparancy1D)
            title([char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
            print('-dtiff',imageResolution,[savedir 'SPM\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ').tiff'])
            savefig([savedir '\FIG\SPM\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ')'])
            close
            
            %   ES
            plotES(ES{comp},ESsd{comp},mapsT{2,comp},Fs,xlab,nx,xlimits,imageFontSize,imageSize,transparancy1D,yLimitES)
            title([char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
            print('-dtiff',imageResolution,[savedir 'ES\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ').tiff'])
            savefig([savedir '\FIG\ES\' eNames{1} ' (' char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ')'])
            close
            
        end
        
        % full plot of means + SPM
        if max(indicesEffects)>2 % no anova required
            plotmeanSPM(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects,eNames,ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{1} ' + SPM.tiff'])
            savefig([savedir '\FIG\' eNames{1} ' + SPM'])
            close
        end
        
        plotmeanSPM(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
        print('-dtiff',imageResolution,[savedir eNames{1} ' + SPMnoAOV.tiff'])
        savefig([savedir '\FIG\' eNames{1} ' + SPMnoAOV'])
        close
        
        if max(indicesEffects)>2 % no anova required
            plotmeanSPMsub(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects,eNames,ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{1} ' + SPMsub.tiff'])
            savefig([savedir '\FIG\' eNames{1} ' + SPMsub'])
            close
        end
        
        plotmeanSPMsub(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
        print('-dtiff',imageResolution,[savedir eNames{1} ' + SPMsubNoAOV.tiff'])
        savefig([savedir '\FIG\' eNames{1} ' + SPMsubNoAOV'])
        close
        
        save([savedir eNames{1}], 'mapsT' , 'Tthreshold', 'namesDifferences', 'mapsDifferences','mapsConditions','namesConditions','testTtests','clustersT','ES')
        clear mapsT Tthreshold namesDifferences comp combi namesConditions mapsDifferences mapsConditions testTtests clustersT ES
        
    end
end


%% T-TESTS 2 EFFECTS - 1 FIXED = MAIN EFFECTS
if nEffects==2
    
    eff=[1;2];
    
    for effectFixed=1:size(eff,1)
        fixedEffect=eff(effectFixed,:);
        mainEffect=1:size(eff,1);
        mainEffect(fixedEffect)=[];
        
        if max(anovaEffects{mainEffect})==1 | doAllInteractions==1
            
            createSavedir([savedir eNames{mainEffect(1)}])
            
            loop=0;
            for i=1:max(indicesEffects(:,mainEffect(1)))
                loop=loop+1;
                combi{loop}=i;
            end
            nCombi=size(combi,2);
            
            legendPlot=[];
            for i=1:nCombi
                meansData{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1),:);
                legendPlot=[legendPlot,{char(modalitiesAll{mainEffect(1)}(combi{i}(1)))}];
                namesConditions{i}=[char(modalitiesAll{mainEffect(1)}(combi{i}(1)))];
            end
            
            % full plot of means
            colorPlot=chooseColor(colorLine,mainEffect(1));
            plotmean(meansData,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits)
            legend(legendPlot,'Location','eastoutside','box','off')
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} '.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)}])
            close
            
            mapsConditions=meansData;
            clear meansData
            
            loop=0;
            for i=1:nCombi
                for j=1:nCombi
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
                    DATA{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{Comp{comp}(i)}(1),:);
                    namesDifferences{comp,i}=[char(modalitiesAll{mainEffect(1)}(combi{Comp{comp}(i)}(1)))];
                end
                
                % t-test
                if typeEffectsAll(mainEffect)==1
                    differencesData{1}=DATA{1}-DATA{2};
                    relativeDifferencesData{1}=100*(DATA{1}-DATA{2})./DATA{2};
                    
                    Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                    testTtests.name{comp}='paired';
                    [ES{comp},ESsd{comp}]=esCalculation(DATA);
                    
                else
                    
                    % differences
                    differencesData{1}=mean(DATA{1})-mean(DATA{2});
                    relativeDifferencesData{1}=100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2});
                    
                    Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                    testTtests.name{comp}='independant';
                    [ES{comp},ESsd{comp}]=esCalculation(DATA);
                end
                
                mapsDifferences{1,comp}=differencesData{1};
                mapsDifferences{2,comp}=relativeDifferencesData{1};
                
                plotmean(differencesData,IC,xlab,ylab,Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
                legend([namesDifferences{comp,1} ' - ' namesDifferences{comp,2}],'Location','eastoutside','box','off')
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '.tiff'])
                savefig([savedir eNames{mainEffect(1)} '\FIG\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                close
                
                plotmean(relativeDifferencesData,IC,xlab,'Differences (%)',Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
                legend([namesDifferences{comp,1} ' - ' namesDifferences{comp,2}],'Location','eastoutside','box','off')
                savefig([savedir eNames{mainEffect(1)} '\FIG\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '%'])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ' %.tiff'])
                close
                
                % inference
                [testTtests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
                testTtests.alphaOriginal{comp}=alphaOriginal;
                testTtests.alpha{comp}=alpha;
                testTtests.nIterations{comp}=iterations;
                Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1));
                Tthreshold{comp}=Ttest_inf.zstar;
                clustersT{comp}=Ttest_inf.clusters;
                mapsT{2,comp}=zeros(dimensions(1),dimensions(2));
                mapsT{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
                mapLogical=abs(mapsT{1,comp})>=Tthreshold{comp};
                mapsT{2,comp}(anovaEffects{mainEffect})=mapLogical(anovaEffects{mainEffect});
                
                % plot of spm analysis
                displayTtest(mapsT{1,comp},Tthreshold{comp},mapsT{2,comp},Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,transparancy1D)
                title([char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                savefig([savedir eNames{mainEffect(1)} '\FIG\SPM\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\SPM\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '.tiff'])
                close
                
                %  ES
                plotES(ES{comp},ESsd{comp},mapsT{2,comp},Fs,xlab,nx,xlimits,imageFontSize,imageSize,transparancy1D,yLimitES)
                title([char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                savefig([savedir eNames{mainEffect(1)} '\FIG\ES\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\ES\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '.tiff'])
                close
                
            end
            
            % full plot of means + SPM
            plotmeanSPM(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects(mainEffect),eNames(mainEffect),ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPM.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPM'])
            close
            
            plotmeanSPM(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPMnoAOV.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPMnoAOV'])
            close
            
            plotmeanSPMsub(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects(mainEffect),eNames(mainEffect),ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPMsub.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPMsub'])
            close
            
            plotmeanSPMsub(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPMsubNoAOV.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPMsubNoAOV'])
            close
            
            mainForInteraction{mainEffect}=mapsT(2,:);
            save([savedir eNames{mainEffect(1)}], 'mapsT' , 'Tthreshold', 'namesDifferences', 'mapsDifferences','mapsConditions','namesConditions','testTtests','clustersT','ES')
            clear mapsT Tthreshold namesDifferences Comp combi namesConditions mapsDifferences mapsConditions testTtests clustersT ES legendPlot
            
        end
    end
end

%% T-TESTS 3 EFFECTS - 2 FIXED = MAIN EFFECTS

if nEffects==3
    
    eff=[1 2; 1 3; 2 3];
    
    for effectFixed=1:size(eff,1)
        fixedEffect=eff(effectFixed,:);
        mainEffect=1:size(eff,1);
        mainEffect(fixedEffect)=[];
        
        if max(anovaEffects{mainEffect})==1 | doAllInteractions==1
            
            createSavedir([savedir eNames{mainEffect(1)}])
            
            loop=0;
            for i=1:max(indicesEffects(:,mainEffect(1)))
                loop=loop+1;
                combi{loop}=i;
            end
            nCombi=size(combi,2);
            
            legendPlot=[];
            for i=1:nCombi
                meansData{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1),:);
                legendPlot=[legendPlot,{char(modalitiesAll{mainEffect(1)}(combi{i}(1)))}];
                namesConditions{i}=[char(modalitiesAll{mainEffect(1)}(combi{i}(1)))];
            end
            
            % full plot of means
            colorPlot=chooseColor(colorLine,mainEffect(1));
            plotmean(meansData,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits)
            legend(legendPlot,'Location','eastoutside','box','off')
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} '.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)}])
            close
            
            mapsConditions=meansData;
            clear meansData
            
            loop=0;
            for i=1:nCombi
                for j=1:nCombi
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
                    DATA{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{Comp{comp}(i)}(1),:);
                    namesDifferences{comp,i}=[char(modalitiesAll{mainEffect(1)}(combi{Comp{comp}(i)}(1)))];
                end
                
                
                %t-test
                if typeEffectsAll(mainEffect)==1
                    differencesData{1}=DATA{1}-DATA{2};
                    relativeDifferencesData{1}=100*(DATA{1}-DATA{2})./DATA{2};
                    
                    Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                    testTtests.name{comp}='paired';
                    [ES{comp},ESsd{comp}]=esCalculation(DATA);
                    
                else
                    
                    % differences
                    differencesData{1}=mean(DATA{1})-mean(DATA{2});
                    relativeDifferencesData{1}=100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2});
                    
                    Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                    testTtests.name{comp}='independant';
                    [ES{comp},ESsd{comp}]=esCalculation(DATA);
                end
                
                mapsDifferences{1,comp}=differencesData{1};
                mapsDifferences{2,comp}=relativeDifferencesData{1};
                
                plotmean(differencesData,IC,xlab,ylab,Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
                legend([namesDifferences{comp,1} ' - ' namesDifferences{comp,2}],'Location','eastoutside','box','off')
                savefig([savedir eNames{mainEffect(1)} '\FIG\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '.tiff'])
                close
                
                plotmean(relativeDifferencesData,IC,xlab,'Differences (%)',Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
                legend([namesDifferences{comp,1} ' - ' namesDifferences{comp,2}],'Location','eastoutside','box','off')
                savefig([savedir eNames{mainEffect(1)} '\FIG\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '%'])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\DIFF\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) ' %.tiff'])
                close
                
                
                % inference
                [testTtests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
                testTtests.alphaOriginal{comp}=alphaOriginal;
                testTtests.alpha{comp}=alpha;
                testTtests.nIterations{comp}=iterations;
                Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1));
                Tthreshold{comp}=Ttest_inf.zstar;
                clustersT{comp}=Ttest_inf.clusters;
                mapsT{2,comp}=zeros(dimensions(1),dimensions(2));
                mapsT{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
                mapLogical=abs(mapsT{1,comp})>=Tthreshold{comp};
                mapsT{2,comp}(anovaEffects{mainEffect})=mapLogical(anovaEffects{mainEffect});
                
                % plot of spm analysis
                displayTtest(mapsT{1,comp},Tthreshold{comp},mapsT{2,comp},Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,transparancy1D)
                title(strrep([char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})],' x ',' \cap '))
                savefig([savedir eNames{mainEffect(1)} '\FIG\SPM\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\SPM\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '.tiff'])
                close
                
                % ES
                plotES(ES{comp},ESsd{comp},mapsT{2,comp},Fs,xlab,nx,xlimits,imageFontSize,imageSize,transparancy1D,yLimitES)
                title(strrep([char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})],' x ',' \cap '))
                savefig([savedir eNames{mainEffect(1)} '\FIG\ES\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2})])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\ES\'  char(namesDifferences{comp,1}) ' - ' char(namesDifferences{comp,2}) '.tiff'])
                close
                
            end
            
            % full plot of means + SPM
            plotmeanSPM(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects(mainEffect(1)),eNames(mainEffect(1)),ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPM.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPM'])
            close
            
            plotmeanSPM(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPMnoAOV.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPMnoAOV'])
            close
            
            plotmeanSPMsub(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects(mainEffect(1)),eNames(mainEffect(1)),ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPMsub.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPMsub'])
            close
            
            plotmeanSPMsub(mapsConditions,mapsT,legendPlot,namesDifferences,IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
            print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} '\' eNames{mainEffect(1)} ' + SPMsubNoAOV.tiff'])
            savefig([savedir eNames{mainEffect(1)} '\FIG\' eNames{mainEffect(1)} ' + SPMsubNoAOV'])
            close
            
            mainForInteraction{mainEffect}=mapsT(2,:);
            save([savedir eNames{mainEffect(1)}], 'mapsT' , 'Tthreshold', 'namesDifferences', 'mapsDifferences','mapsConditions','namesConditions','testTtests','clustersT','ES')
            clear mapsT Tthreshold namesDifferences Comp combi namesConditions mapsDifferences mapsConditions testTtests clustersT ES legendPlot
            
        end
    end
end

%% T-TESTS 3 EFFECTS - 1 FIXED = INTERACTION
if nEffects==3
    
    for effectFixed=1:3
        
        fixedEffect=effectFixed;
        mainEffect=1:3;
        mainEffect(effectFixed)=[];
        anovaFixedCorr=[3 2 1];
        
        if max(anovaEffects{3+anovaFixedCorr(fixedEffect)})==1 | doAllInteractions==1
            
            for e=1:2
                createSavedir([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(e)}])
            end
            
            loop=0;
            for i=1:max(indicesEffects(:,mainEffect(1)))
                for j=1:max(indicesEffects(:,mainEffect(2)))
                    loop=loop+1;
                    combi{loop}=[i j];
                end
            end
            nCombi=size(combi,2);
            
            legendPlot=[];
            for i=1:nCombi
                meansData{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{i}(1) & indicesEffects(:,mainEffect(2))==combi{i}(2),:);
                legendPlot=[legendPlot,{[char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' \cap ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))]}];
                namesConditions{i}=[char(modalitiesAll{mainEffect(1)}(combi{i}(1))) ' \cap ' char(modalitiesAll{mainEffect(2)}(combi{i}(2)))];
            end
            
            % full plot of means
            [nPlot,whichPlot,whichFixed,whichModal]=findNPlot(combi);
            for p=1:nPlot
                colorPlot=chooseColor(colorLine,mainEffect(whichFixed(2,p)));
                plotmean(meansData(whichPlot{p}),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits)
                legend(legendPlot(whichPlot{p}),'Location','eastoutside','box','off')
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} '.tiff'])
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\FIG\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)}])
                close
            end
            
            mapsConditions=meansData;
            clear meansData
            
            loop=0;
            for i=1:nCombi
                for j=1:nCombi
                    if i<j
                        if max(size(find(combi{i}~=combi{j})))==1
                            loop=loop+1;
                            Comp{loop}=[i j];
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
            
            for comp=1:nComp
                
                for i=1:2
                    % comparison + name
                    DATA{i}=maps1d(indicesEffects(:,mainEffect(1))==combi{Comp{comp}(i)}(1) & indicesEffects(:,mainEffect(2))==combi{Comp{comp}(i)}(2),:);
                    intForInteractions{anovaFixedCorr(effectFixed)}.comp{comp}(i,:)=combi{Comp{comp}(i)};
                end
                [eFixed,eTested,modalFixed,modalTested]=findWhichTitle([combi{Comp{comp}(1)};combi{Comp{comp}(2)}]);
                namesDifferences{comp}=char([modalitiesAll{mainEffect(eFixed)}{modalFixed} ' (' modalitiesAll{mainEffect(eTested)}{modalTested(1)} ' - ' modalitiesAll{mainEffect(eTested)}{modalTested(2)} ')']);
                
                
                % t-test
                if typeEffectsAll(mainEffect(eTested))==1
                    differencesData{1}=DATA{1}-DATA{2};
                    relativeDifferencesData{1}=100*(DATA{1}-DATA{2})./DATA{2};
                    
                    Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                    testTtests.name{comp}='paired';
                    [ES{comp},ESsd{comp}]=esCalculation(DATA);
                    
                else
                    
                    % differences
                    differencesData{1}=mean(DATA{1})-mean(DATA{2});
                    relativeDifferencesData{1}=100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2});
                    
                    Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                    testTtests.name{comp}='independant';
                    [ES{comp},ESsd{comp}]=esCalculation(DATA);
                end
                
                mapsDifferences{1,comp}=differencesData{1};
                mapsDifferences{2,comp}=relativeDifferencesData{1};
                
                plotmean(differencesData,IC,xlab,ylab,Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
                legend([namesDifferences{comp}],'Location','eastoutside','box','off')
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\FIG\DIFF\' namesDifferences{comp}])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\DIFF\' namesDifferences{comp} '.tiff'])
                close
                
                plotmean(relativeDifferencesData,IC,xlab,'Differences (%)',Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
                legend([namesDifferences{comp}],'Location','eastoutside','box','off')
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\FIG\DIFF\' namesDifferences{comp} '%'])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\DIFF\' namesDifferences{comp} ' %.tiff'])
                close
                
                % inference
                [testTtests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
                testTtests.alphaOriginal{comp}=alphaOriginal;
                testTtests.alpha{comp}=alpha;
                testTtests.nIterations{comp}=iterations;
                Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1));
                Tthreshold{comp}=Ttest_inf.zstar;
                clustersT{comp}=Ttest_inf.clusters;
                mapsT{2,comp}=zeros(dimensions(1),dimensions(2));
                mapsT{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
                mapLogical=abs(mapsT{1,comp})>=Tthreshold{comp};
                effectCorr=anovaEffects{3+anovaFixedCorr(fixedEffect)}(:);
                mapsT{2,comp}(effectCorr)=mapLogical(effectCorr);
                indiceMain=findWhichMain(modalitiesAll{mainEffect(testedEffect{comp})},combi{Comp{comp}(1)}(testedEffect{comp}),combi{Comp{comp}(2)}(testedEffect{comp}));
                tMainEffect=abs(mainForInteraction{mainEffect(testedEffect{comp})}{indiceMain})>0;
                tMainEffect(effectCorr==1)=0;
                realEffect{comp}=reshape(max([tMainEffect(:)';mapsT{2,comp}(:)']),dimensions(1),dimensions(2));
                mapsT{2,comp}=realEffect{comp};
                
                % plot of spm analysis
                displayTtest(mapsT{1,comp},Tthreshold{comp},mapsT{2,comp},Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,transparancy1D)
                title(namesDifferences{comp})
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\FIG\SPM\' namesDifferences{comp}])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\SPM\' namesDifferences{comp} '.tiff'])
                close
                
                %   ES
                plotES(ES{comp},ESsd{comp},mapsT{2,comp},Fs,xlab,nx,xlimits,imageFontSize,imageSize,transparancy1D,yLimitES)
                title(namesDifferences{comp})
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\FIG\ES\' namesDifferences{comp}])
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(eTested)} '\ES\' namesDifferences{comp} '.tiff'])
                close
                
            end
            
            % full plot of means + SPM
            for p=1:nPlot
                data4empty=mapsConditions(whichPlot{p});
                for i=1:numel(whichPlot{p})
                    isEmptydata(i)=~isempty(data4empty{i});
                end
                
                for nC=1:numel(whichPlot{p})
                    findT(nC)=namesConditions(whichPlot{p}(nC));
                    capPos(nC,:)=strfind(findT{nC},' \cap ');
                end
                if mean(diff(capPos)~=0)>0 % same letter at the end
                    sameName=findT{1}(capPos(1)+6:end);
                else
                    if findT{1}(1:capPos(1)-1)==findT{2}(1:capPos(1)-1) % start
                        sameName=findT{1}(1:capPos(1)-1);
                    else
                        sameName=findT{1}(capPos(1)+6:end); % end
                    end
                end
                sizeSname=numel(sameName);
                for nC=1:numel(namesDifferences)
                    whichCompare(nC)=strcmp(sameName,namesDifferences{nC}(1:sizeSname));
                end
                
                colorPlot=chooseColor(colorLine,mainEffect(whichFixed(2,p)));
                nAnova=whichAnova(mainEffect);
                
                plotmeanSPM(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects([mainEffect(whichFixed(2,p)), nAnova]),{eNames{mainEffect(whichFixed(2,p))},[eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]},ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' + SPM.tiff'])
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\FIG\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' +SPM'])
                close
                
                plotmeanSPM(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' + SPMnoAOV.tiff'])
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\FIG\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' +SPMnoAOV'])
                close
                
                plotmeanSPMsub(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects([mainEffect(whichFixed(2,p)), nAnova]),{eNames{mainEffect(whichFixed(2,p))},[eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}]},ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' + SPMsub.tiff'])
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\FIG\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' +SPMsub'])
                close
                
                plotmeanSPMsub(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' + SPMsubNoAOV.tiff'])
                savefig([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)} '\' eNames{mainEffect(whichFixed(2,p))} '\FIG\' modalitiesAll{mainEffect(whichFixed(1,p))}{whichModal(p)} ' +SPMsubNoAOV'])
                close
                
                clear isEmptydata findT capPos whichCompare
                
            end
            
            intForInteractions{anovaFixedCorr(effectFixed)}.t=realEffect;
            save([savedir eNames{mainEffect(1)} ' x ' eNames{mainEffect(2)}], 'mapsT' , 'Tthreshold', 'namesDifferences', 'mapsDifferences','mapsConditions','namesConditions','testTtests','clustersT','ES')
            clear mapsT Tthreshold namesDifferences Comp combi namesConditions mapsDifferences mapsConditions testTtests clustersT ES legendPlot
            
        end
    end
end

%% T-TESTS ALL INTERACTIONS (ANOVA 2 and 3)
if nEffects>1
    
    if nEffects==2
        isInteraction=max(anovaEffects{3});
        savedir2=[ eNames{1} ' x ' eNames{2} '\'] ;
        if isInteraction==1 | doAllInteractions==1
            createSavedir([savedir savedir2 eNames{1}])
            createSavedir([savedir savedir2 eNames{2}])
        end
        figname =[ eNames{1} ' x ' eNames{2}];
    elseif nEffects==3
        isInteraction=max(anovaEffects{7});
        savedir2=[ eNames{1} ' x ' eNames{2} ' x ' eNames{3} '\'];
        if isInteraction==1 | doAllInteractions==1
            createSavedir([savedir savedir2 eNames{1}])
            createSavedir([savedir savedir2 eNames{2}])
            createSavedir([savedir savedir2 eNames{3}])
        end
        figname=[ eNames{1} ' x ' eNames{2} ' x ' eNames{3}];
    end
    
    
    if isInteraction==1 | doAllInteractions==1
        
        loop=0;
        f1=figure('Units', 'Normalized', 'OuterPosition', [0, 0, 1, 1],'visible','off');
        
        % number of combinations + plot of each
        if nEffects==2
            
            for i=1:max(indicesEffects(:,1))
                for j=1:max(indicesEffects(:,2))
                    loop=loop+1;
                    combi{loop}=[i j];
                end
            end
            nCombi=size(combi,2);
            
            legendPlot=[];
            for i=1:nCombi
                meansData{i}=maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2),:);
                legendPlot=[legendPlot,{[char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2)))]}];
                namesConditions{i}=[char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2)))];
            end
            
            % full plot of means
            [nPlot,whichPlot,whichFixed,whichModal]=findNPlot(combi);
            for p=1:nPlot
                colorPlot=chooseColor(colorLine,whichFixed(2,p));
                plotmean(meansData(whichPlot{p}),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits)
                data4empty=meansData(whichPlot{p});
                for i=1:numel(whichPlot{p})
                    isEmptydata(i)=~isempty(data4empty{i});
                end
                legend(legendPlot(whichPlot{p}(isEmptydata)),'Location','eastoutside','box','off')
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(2,p)} '\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} '.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(2,p)} '\FIG\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)}])
                close
                clear isEmptydata
            end
            
            mapsConditions=meansData;
            clear meansData
            
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
            
            legendPlot=[];
            for i=1:nCombi
                meansData{i}=maps1d(indicesEffects(:,1)==combi{i}(1) & indicesEffects(:,2)==combi{i}(2) & indicesEffects(:,3)==combi{i}(3),:);
                legendPlot=[legendPlot,{[char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2))) ' \cap ' char(modalitiesAll{3}(combi{i}(3)))]}];
                namesConditions{i}=[char(modalitiesAll{1}(combi{i}(1))) ' \cap ' char(modalitiesAll{2}(combi{i}(2))) ' \cap ' char(modalitiesAll{3}(combi{i}(3)))];
            end
            
            [nPlot,whichPlot,whichFixed,whichModal]=findNPlot(combi);
            for p=1:nPlot
                colorPlot=chooseColor(colorLine,whichFixed(1,p));
                plotmean(meansData(whichPlot{p}),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits)
                legend(legendPlot(whichPlot{p}),'Location','eastoutside','box','off')
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(1,p)} '\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} '.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(1,p)} '\FIG\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)}])
                close
            end
            mapsConditions=meansData;
            clear meansData
        end
        
        % number of comparisons + plot of each
        loop=0;
        for i=1:nCombi
            for j=1:nCombi
                if i<j
                    if max(size(find(combi{i}~=combi{j})))==1
                        loop=loop+1;
                        Comp{loop}=[i j];
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
        
        for comp=1:nComp
            
            for i=1:2
                % comparison + name
                if nEffects==2
                    DATA{i}=maps1d(indicesEffects(:,1)==combi{Comp{comp}(i)}(1) & indicesEffects(:,2)==combi{Comp{comp}(i)}(2),:);
                    [eFixed,eTested,modalFixed,modalTested]=findWhichTitle([combi{Comp{comp}(1)};combi{Comp{comp}(2)}]);
                    namesDifferences{comp}=char([modalitiesAll{eFixed}{modalFixed} ' (' modalitiesAll{eTested}{modalTested(1)} ' - ' modalitiesAll{eTested}{modalTested(2)} ')']);
                elseif nEffects==3
                    DATA{i}=maps1d(indicesEffects(:,1)==combi{Comp{comp}(i)}(1) & indicesEffects(:,2)==combi{Comp{comp}(i)}(2) & indicesEffects(:,3)==combi{Comp{comp}(i)}(3),:);
                    [eFixed,eTested,modalFixed,modalTested]=findWhichTitle([combi{Comp{comp}(1)};combi{Comp{comp}(2)}]);
                    namesDifferences{comp}=char([modalitiesAll{eFixed(1)}{modalFixed(1)} ' x ' modalitiesAll{eFixed(2)}{modalFixed(2)} ' (' modalitiesAll{eTested}{modalTested(1)} ' - ' modalitiesAll{eTested}{modalTested(2)} ')']);
                end
            end
            
            
            % t-test
            if typeEffectsAll(eTested)==1
                differencesData{1}=DATA{1}-DATA{2};
                relativeDifferencesData{1}=100*(DATA{1}-DATA{2})./DATA{2};
                
                Ttest=spm1d.stats.nonparam.ttest_paired(DATA{1},DATA{2});
                testTtests.name{comp}='paired';
                [ES{comp},ESsd{comp}]=esCalculation(DATA);
                
            else
                
                % differences
                differencesData{1}=mean(DATA{1})-mean(DATA{2});
                relativeDifferencesData{1}=100*(mean(DATA{1})-mean(DATA{2}))./mean(DATA{2});
                
                Ttest=spm1d.stats.nonparam.ttest2(DATA{1},DATA{2});
                testTtests.name{comp}='independant';
                [ES{comp},ESsd{comp}]=esCalculation(DATA);
            end
            
            mapsDifferences{1,comp}=differencesData{1};
            mapsDifferences{2,comp}=relativeDifferencesData{1};
            
            plotmean(differencesData,IC,xlab,ylab,Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
            legend([namesDifferences{comp}],'Location','eastoutside','box','off')
            savefig([savedir savedir2 eNames{testedEffect{comp}} '\FIG\DIFF\' namesDifferences{comp}])
            print('-dtiff',imageResolution,[savedir savedir2 eNames{testedEffect{comp}} '\DIFF\' namesDifferences{comp} '.tiff'])
            close
            
            plotmean(relativeDifferencesData,IC,xlab,'Differences (%)',Fs,xlimits,nx,[],[],imageFontSize,imageSize,transparancy1D,[])
            legend([namesDifferences{comp}],'Location','eastoutside','box','off')
            savefig([savedir savedir2 eNames{testedEffect{comp}} '\FIG\DIFF\' namesDifferences{comp} '%'])
            print('-dtiff',imageResolution,[savedir savedir2 eNames{testedEffect{comp}} '\DIFF\' namesDifferences{comp} ' %.tiff'])
            close
            
            % inference
            [testTtests.nWarning{comp},iterations,alpha]=fctWarningIterations(Ttest,alphaOriginal,multiIterations,maximalIT,IT);
            testTtests.alphaOriginal{comp}=alphaOriginal;
            testTtests.alpha{comp}=alpha;
            testTtests.nIterations{comp}=iterations;
            Ttest_inf=Ttest.inference(alpha,'iterations',iterations,'force_iterations',logical(1));
            clustersT{comp}=Ttest_inf.clusters;
            Tthreshold{comp}=Ttest_inf.zstar;
            mapsT{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
            mapsT{2,comp}=zeros(dimensions(1),dimensions(2));
            mapsT{1,comp}=reshape(Ttest_inf.z,dimensions(1),dimensions(2));
            mapLogical=abs(mapsT{1,comp})>=Tthreshold{comp};
            if nEffects==2
                indiceMain=findWhichMain(modalitiesAll{testedEffect{comp}},combi{Comp{comp}(1)}(testedEffect{comp}),combi{Comp{comp}(2)}(testedEffect{comp}));
                tMainEffect=abs(mainForInteraction{testedEffect{comp}}{indiceMain})>0;
                effectCorr=anovaEffects{3}(:);
            else
                
                intLocations=[4 5;4 6;5 6]-3;
                for interactions=1:2
                    indiceInteraction=findWhichInteraction(intForInteractions{intLocations(testedEffect{comp},interactions)}.comp,combi(Comp{comp}),interactions,testedEffect{comp});
                    tInteractionEffect{interactions}=intForInteractions{intLocations(testedEffect{comp},interactions)}.t{indiceInteraction}(:);
                end
                effectCorr=anovaEffects{7};
            end
            
            mapsT{2,comp}(effectCorr)=mapLogical(effectCorr);
            if nEffects==2
                tMainEffect(effectCorr==1)=0;
                realEffect{comp}=reshape(max([tMainEffect(:)';mapsT{2,comp}(:)']),dimensions(1),dimensions(2));
            else
                for interactions=1:2
                    tInteractionEffect{interactions}(effectCorr==1)=0;
                end
                realEffect{comp}=reshape(max([tInteractionEffect{1}';tInteractionEffect{2}';mapsT{2,comp}(:)']),dimensions(1),dimensions(2));
            end
            mapsT{2,comp}=realEffect{comp};
            
            % full plot of spm analysis
            displayTtest(mapsT{1,comp},Tthreshold{comp},mapsT{2,comp},Fs,xlab,ylab,ylimits,dimensions,nx,ny,xlimits,imageFontSize,imageSize,transparancy1D)
            title(namesDifferences{comp})
            savefig([savedir savedir2 eNames{testedEffect{comp}} '\FIG\SPM\' namesDifferences{comp}])
            print('-dtiff',imageResolution,[savedir savedir2 eNames{testedEffect{comp}} '\SPM\' namesDifferences{comp} '.tiff'])
            close
            
            % ES
            plotES(ES{comp},ESsd{comp},mapsT{2,comp},Fs,xlab,nx,xlimits,imageFontSize,imageSize,transparancy1D,yLimitES)
            title(namesDifferences{comp})
            savefig([savedir savedir2 eNames{testedEffect{comp}} '\FIG\ES\' namesDifferences{comp}])
            print('-dtiff',imageResolution,[savedir savedir2 eNames{testedEffect{comp}} '\ES\' namesDifferences{comp} '.tiff'])
            close
            
        end
        
        
        for p=1:nPlot
            
            data4empty=mapsConditions(whichPlot{p});
            for i=1:numel(whichPlot{p})
                isEmptydata(i)=~isempty(data4empty{i});
            end
            
            for nC=1:numel(whichPlot{p})
                findT(nC)=namesConditions(whichPlot{p}(nC));
                capPos(nC,:)=strfind(findT{nC},' \cap ');
            end
            
            if size(capPos,2)==1 % ANOVA 2
                if mean(diff(capPos)~=0)>0 % same letter at the end
                    sameName=findT{1}(capPos(1)+6:end);
                else
                    if findT{1}(1:capPos(1)-1)==findT{2}(1:capPos(1)-1) % start
                        sameName=findT{1}(1:capPos(1)-1);
                    else
                        sameName=findT{1}(capPos(1)+6:end); % end
                    end
                end
                
                sameName=strrep(sameName,'\cap','x');
                
            else % ANOVA 3
                
                for i=1:numel(findT)
                    iFirst{i}=findT{i}(1:capPos(i,1)-1);
                    iSecond{i}=findT{i}(capPos(i,1)+6:capPos(i,2)-1);
                    iThird{i}=findT{i}(capPos(i,2)+6:end);
                end
                
                if ~strcmp(iFirst{1},iFirst{2}) % start
                    sameName=[iSecond{1} ' x ' iThird{1}];
                elseif ~strcmp(iSecond{1},iSecond{2})
                    sameName=[iFirst{1} ' x ' iThird{1}];
                else
                    sameName=[iFirst{1} ' x ' iSecond{1}];
                end
                
            end
            
            sizeSname=numel(sameName);
            for nC=1:numel(namesDifferences)
                whichCompare(nC)=strcmp(sameName,namesDifferences{nC}(1:sizeSname));
            end
            
            if nEffects==2
                colorPlot=chooseColor(colorLine,whichFixed(2,p));
            else
                colorPlot=chooseColor(colorLine,whichFixed(1,p));
            end
            
            if nEffects==2
                plotmeanSPM(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects([whichFixed(2,p) 3]),{eNames{whichFixed(2,p)},[eNames{1} ' x ' eNames{2}]},ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(2,p)} '\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPM.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(2,p)} '\FIG\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPM'])
                close
                
                plotmeanSPM(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(2,p)} '\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPMnoAOV.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(2,p)} '\FIG\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPMnoAOV'])
                close
                
                plotmeanSPMsub(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,anovaEffects([whichFixed(2,p) 3]),{eNames{whichFixed(2,p)},[eNames{1} ' x ' eNames{2}]},ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(2,p)} '\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPMsub.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(2,p)} '\FIG\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPMsub'])
                close
                
                plotmeanSPMsub(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(2,p)} '\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPMsubNoAOV.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(2,p)} '\FIG\' modalitiesAll{whichFixed(1,p)}{whichModal(1,p)} ' + SPMsubNoAOV'])
                close
            else
                [nAnovaInt,nNames]=whichAnovaInt(whichFixed(1,p));
                
                plotmeanSPM(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,...
                    anovaEffects([whichFixed(1,p) nAnovaInt 7]),{eNames{whichFixed(1,p)},[eNames{nNames(1,1)} ' x ' eNames{nNames(1,2)}], [eNames{nNames(2,1)} ' x ' eNames{nNames(2,2)}],[eNames{1} ' x ' eNames{2} ' x ' eNames{3}]},ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(1,p)} '\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPM.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(1,p)} '\FIG\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPM'])
                close
                
                plotmeanSPM(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(1,p)} '\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPMnoAOV.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(1,p)} '\FIG\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPMnoAOV'])
                close
                
                plotmeanSPMsub(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,...
                    anovaEffects([whichFixed(1,p) nAnovaInt 7]),{eNames{whichFixed(1,p)},[eNames{nNames(1,1)} ' x ' eNames{nNames(1,2)}], [eNames{nNames(2,1)} ' x ' eNames{nNames(2,2)}],[eNames{1} ' x ' eNames{2} ' x ' eNames{3}]},ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(1,p)} '\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPMsub.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(1,p)} '\FIG\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPMsub'])
                close
                
                plotmeanSPMsub(mapsConditions(whichPlot{p}),mapsT(:,whichCompare),legendPlot(whichPlot{p}(isEmptydata)),namesDifferences(whichCompare),IC,xlab,ylab,Fs,xlimits,nx,ny,colorPlot,imageFontSize,imageSize,transparancy1D,ylimits,[],[],ratioSPM,spmPos,aovColor)
                print('-dtiff',imageResolution,[savedir savedir2 eNames{whichFixed(1,p)} '\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPMsubNoAOV.tiff'])
                savefig([savedir savedir2 eNames{whichFixed(1,p)} '\FIG\' modalitiesAll{whichFixed(2,p)}{whichModal(1,p)} ' x ' modalitiesAll{whichFixed(3,p)}{whichModal(2,p)} ' + SPMsubNoAOV'])
                close
            end
            
            clear isEmptydata findT capPos whichCompare
        end
        
        
        save([savedir figname], 'mapsT' , 'Tthreshold', 'namesDifferences', 'mapsDifferences','mapsConditions','namesConditions','testTtests','clustersT','ES')
        clear mapsT Tthreshold namesDifferences Comp combi namesConditions mapsDifferences mapsConditions testTtests clustersT ES legendPlot
    end
    
end
end