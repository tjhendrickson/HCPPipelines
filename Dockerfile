# Use Ubuntu 14.04 LTS
FROM ubuntu:trusty-20170119

# Configure environment
ENV OS Linux
ENV FS_OVERRIDE 0
ENV FIX_VERTEX_AREA=
ENV SUBJECTS_DIR /opt/freesurfer/subjects
ENV FSF_OUTPUT_FORMAT nii.gz
ENV MNI_DIR /opt/freesurfer/mni
ENV LOCAL_DIR /opt/freesurfer/local
ENV FREESURFER_HOME /opt/freesurfer
ENV FSFAST_HOME /opt/freesurfer/fsfast
ENV MINC_BIN_DIR /opt/freesurfer/mni/bin
ENV MINC_LIB_DIR /opt/freesurfer/mni/lib
ENV MNI_DATAPATH /opt/freesurfer/mni/data
ENV FMRI_ANALYSIS_DIR /opt/freesurfer/fsfast
ENV PERL5LIB /opt/freesurfer/mni/lib/perl5/5.8.5
ENV MNI_PERL5LIB /opt/freesurfer/mni/lib/perl5/5.8.5
ENV PATH /opt/freesurfer/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
ENV PYTHONPATH=""
ENV FSL_FIXDIR /opt/fix
ENV FSLDIR=/usr/share/fsl/5.0
ENV FSL_DIR="${FSLDIR}"
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV PATH=/usr/lib/fsl/5.0:$PATH
ENV FSLMULTIFILEQUIT=TRUE
ENV POSSUMDIR=/usr/share/fsl/5.0
ENV LD_LIBRARY_PATH=/usr/lib/fsl/5.0
ENV FSLTCLSH=/usr/bin/tclsh
ENV FSLWISH=/usr/bin/wish
ENV FSLOUTPUTTYPE=NIFTI_GZ

# Download FreeSurfer
RUN apt-get -y update \
    && apt-get install -y wget && \
    wget -qO- ftp://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/5.3.0-HCP/freesurfer-Linux-centos4_x86_64-stable-pub-v5.3.0-HCP.tar.gz | tar zxv -C /opt \
    --exclude='freesurfer/trctrain' \
    --exclude='freesurfer/subjects/fsaverage_sym' \
    --exclude='freesurfer/subjects/fsaverage3' \
    --exclude='freesurfer/subjects/fsaverage4' \
    --exclude='freesurfer/subjects/fsaverage5' \
    --exclude='freesurfer/subjects/fsaverage6' \
    --exclude='freesurfer/subjects/cvs_avg35' \
    --exclude='freesurfer/subjects/cvs_avg35_inMNI152' \
    --exclude='freesurfer/subjects/bert' \
    --exclude='freesurfer/subjects/V1_average' \
    --exclude='freesurfer/average/mult-comp-cor' \
    --exclude='freesurfer/lib/cuda' \
    --exclude='freesurfer/lib/qt' && \
    apt-get install -y tcsh bc tar libgomp1 perl-modules curl

RUN sed -i -e 's,main *$,main contrib non-free,g' /etc/apt/sources.list.d/neurodebian.sources.list; grep -q 'deb .* multiverse$' /etc/apt/sources.list || sed -i -e 's,universe *$,universe multiverse,g' /etc/apt/sources.list

# Install FSL 5.0.9
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    curl -sSL http://neuro.debian.net/lists/trusty.us-ca.full >> /etc/apt/sources.list.d/neurodebian.sources.list

RUN apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9

RUN apt-get update && \
    apt-get install -y fsl-core=5.0.9-4~nd14.04+1

RUN apt-get build-dep -y gridengine && apt-get update -y

# Install Connectome Workbench
RUN apt-get update && apt-get -y install connectome-workbench=1.2.3-1~nd14.04+1


# Install HCP Pipelines
RUN apt-get update \
    && apt-get install -y --no-install-recommends python-numpy && \
    wget https://github.com/Washington-University/Pipelines/archive/v3.17.0.tar.gz -O pipelines.tar.gz && \
    cd /opt/ && \
    mkdir /opt/HCP-Pipelines && \
    tar zxf /pipelines.tar.gz -C /opt/HCP-Pipelines --strip-components=1 && \
    rm /pipelines.tar.gz

# Install FIX
RUN apt-get update && apt-get install -y build-essential libpcre3 libpcre3-dev  fort77 xorg-dev libbz2-dev liblzma-dev libblas-dev gfortran gcc-multilib gobjc++ libreadline-dev bzip2 libcurl4-gnutls-dev default-jdk gdebi

RUN cd /opt && \
    wget http://www.fmrib.ox.ac.uk/~steve/ftp/fix.tar.gz && \
    tar zxvf fix.tar.gz && \
    rm fix.tar.gz
RUN mv /opt/fix* /opt/fix

RUN cd /opt && \
    wget https://cloud.r-project.org/bin/linux/ubuntu/trusty/r-base-core_3.4.4-1trusty0_amd64.deb && \
    wget https://cloud.r-project.org/bin/linux/ubuntu/trusty/r-base-dev_3.4.4-1trusty0_all.deb && \
    gdebi -n r-base-core_3.4.4-1trusty0_amd64.deb && \
    gdebi -n r-base-dev_3.4.4-1trusty0_all.deb && \
    apt-get install -y libssl-dev 

RUN R --vanilla -e "install.packages('coin', repos='http://cran.us.r-project.org', dependencies=TRUE)" -e "install.packages('strucchange', repos='http://cran.us.r-project.org', dependencies=TRUE)" -e "install.packages('https://cran.r-project.org/src/contrib/Archive/party/party_1.0-25.tar.gz', repos=NULL, type='source')" -e "install.packages('https://cran.r-project.org/src/contrib/Archive/kernlab/kernlab_0.9-24.tar.gz', repos=NULL, type='source')" -e "install.packages('ROCR', repos='http://cran.us.r-project.org', dependencies=TRUE)" -e "install.packages('https://cran.r-project.org/src/contrib/Archive/e1071/e1071_1.6-7.tar.gz', repos=NULL, type='source')" -e "install.packages('https://cran.r-project.org/src/contrib/Archive/randomForest/randomForest_4.6-12.tar.gz', repos=NULL, type='source')"

RUN mkdir /tmp/v83 && \
    cp /opt/fix*/compiled/Linux/x86_64/MCRInstaller.zip /tmp/v83 && \
    cd /tmp/v83 && \
    unzip MCRInstaller.zip

COPY modified_files/MCR_installer_input_v83.txt /tmp/v83/MCR_installer_input.txt
RUN  cd /tmp/v83 && ./install -mode silent -inputFile MCR_installer_input.txt

# Ensure Dependencies for PostFix are met
RUN apt-get update
RUN mkdir /tmp/v81 && \
    cd /tmp/v81 && \
    wget http://ssd.mathworks.com/supportfiles/MCR_Runtime/R2013a/MCR_R2013a_glnxa64_installer.zip && \
    unzip MCR_R2013a_glnxa64_installer.zip
COPY modified_files/MCR_installer_input_v81.txt /tmp/v81/MCR_installer_input.txt
RUN  cd /tmp/v81 && ./install -mode silent -inputFile MCR_installer_input.txt

#Create necessary environment variables
RUN echo "cHJpbnRmICJrcnp5c3p0b2YuZ29yZ29sZXdza2lAZ21haWwuY29tXG41MTcyXG4gKkN2dW12RVYzelRmZ1xuRlM1Si8yYzFhZ2c0RVxuIiA+IC9vcHQvZnJlZXN1cmZlci9saWNlbnNlLnR4dAo=" | base64 -d | sh
ENV CARET7DIR=/usr/bin
ENV HCPPIPEDIR=/opt/HCP-Pipelines
ENV HCPPIPEDIR_Templates=${HCPPIPEDIR}/global/templates
ENV HCPPIPEDIR_Bin=${HCPPIPEDIR}/global/binaries
ENV HCPPIPEDIR_Config=${HCPPIPEDIR}/global/config
ENV HCPPIPEDIR_PreFS=${HCPPIPEDIR}/PreFreeSurfer/scripts
ENV HCPPIPEDIR_FS=${HCPPIPEDIR}/FreeSurfer/scripts
ENV HCPPIPEDIR_PostFS=${HCPPIPEDIR}/PostFreeSurfer/scripts
ENV HCPPIPEDIR_fMRISurf=${HCPPIPEDIR}/fMRISurface/scripts
ENV HCPPIPEDIR_fMRIVol=${HCPPIPEDIR}/fMRIVolume/scripts
ENV HCPPIPEDIR_tfMRI=${HCPPIPEDIR}/tfMRI/scripts
ENV HCPPIPEDIR_dMRI=${HCPPIPEDIR}/DiffusionPreprocessing/scripts
ENV HCPPIPEDIR_dMRITract=${HCPPIPEDIR}/DiffusionTractography/scripts
ENV HCPPIPEDIR_Global=${HCPPIPEDIR}/global/scripts
ENV HCPPIPEDIR_tfMRIAnalysis=${HCPPIPEDIR}/TaskfMRIAnalysis/scripts
ENV MSMBin=${HCPPIPEDIR}/MSMBinaries

# Install python Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends python-pip python-six python-nibabel python-setuptools
RUN pip install pybids==0.5.1
RUN pip install --upgrade pybids


#make /bids_dir and /output_dir
RUN mkdir /bids_dir && \
    mkdir /output_dir 
    
#create 360CortSurf_19Vol_parcel.dlabel.nii
RUN cd / && \
	wget https://github.umn.edu/hendr522/HCPPipelines/blob/master/modified_files/360CortSurf_19Vol_parcel.dlabel.nii

## Install the validator
RUN apt-get update && \
    apt-get install -y curl && \
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get remove -y curl && \
    apt-get install -y nodejs

RUN npm install -g bids-validator@0.26.11

RUN apt-get update && apt-get install -y --no-install-recommends python-pip python-six python-nibabel python-setuptools
RUN pip install pybids==0.5.1
ENV PYTHONPATH=""

COPY run.py /run.py
RUN chmod 555 /run.py

COPY version /version
COPY IntendedFor.py /IntendedFor.py
COPY modified_files/fsl_sub /usr/lib/fsl/5.0/fsl_sub
COPY modified_files/settings.sh /opt/fix/settings.sh
COPY modified_files/360CortSurf_19Vol_parcel.dlabel.nii /360CortSurf_19Vol_parcel.dlabel.nii
COPY modified_files/PostFix.sh /opt/HCP-Pipelines/PostFix/PostFix.sh
COPY modified_files/run_prepareICAs.sh /opt/HCP-Pipelines/PostFix/Compiled_prepareICAs/distrib/run_prepareICAs.sh
COPY modified_files/RestingStateStats.sh /opt/HCP-Pipelines/RestingStateStats/RestingStateStats.sh
COPY modified_files/run_RestingStateStats.sh /opt/HCP-Pipelines/RestingStateStats/Compiled_RestingStateStats/distrib/run_RestingStateStats.sh


ENTRYPOINT ["/run.py"]
