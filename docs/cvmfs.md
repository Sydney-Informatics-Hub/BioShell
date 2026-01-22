# CernVM-FS (CVMFS)

## What is CVMFS?
CernVM-FS (CVMFS) is a read-only, network-distributed filesystem originally developed to deliver software and data efficiently at scale. In BioImage, CVMFS is used to provide access to shared resources—such as container images, reference datasets, and other commonly used scientific files—without requiring them to be installed or copied onto each VM.

## Why BioImage uses CVMFS
- Lightweight (smaller VM images)
- Consistent (everyone sees the same tools/data)
- Easier to maintain (updates happen centrally)
- Faster to start using (no lengthy setup per user or per workshop)

**Note:** The first time you access a CVMFS path it may take a minute or two to respond, because content is fetched on-demand and cached. Subsequent access is typically much faster.

[TODO]: list available repositories and whats in them.  Add commands to ls with example output