﻿
namespace NuBuild
{
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Linq;

   
    class FStarDepOutput : VirtualContents
    {
        public readonly OrderPreservingSet<BuildObject> Value;

        public FStarDepOutput(string output, WorkingDirectory workDir)
        {
            this.Value = this.ParseOutput(output,  workDir);
        }

        private OrderPreservingSet<BuildObject> ParseOutput(string output, WorkingDirectory workDir)
        {
            var stdDeps = FStarEnvironment.GetStandardDependencies();
            var set = new OrderPreservingSet<BuildObject>();
            var entries = output.Split(new[] { '\n' }, StringSplitOptions.RemoveEmptyEntries).ToList();

            // todo: verify that the final file is actually the source file.
            /*var lastFile = entries[entries.Count - 1].ToAbsoluteFilePath();
            var workSource = workDir.GetAbsoluteFilePath(FileSystemPath.ImplicitPathStringToRelativeFilePath(workDir.PathTo(fstSource)));
            if (workSource.NotEquals(lastFile))
            {
                throw new InvalidOperationException("`fstar.exe --find_deps` did not return the top-level source file in its output");
            }*/
            entries.RemoveAt(entries.Count - 1);

            // we need to search for dependencies that refer to files that come with the F* distribution to ensure that NuBuild handles those dependencies properly.
            foreach (var entry in entries)
            {
                var absFilePath = AbsoluteFileSystemPath.Parse(entry);
                var relFilePath = absFilePath.MapToBuildObjectPath(workDir);
                BuildObject foundStdDep = null;
                foreach (var stdDep in stdDeps)
                {
                    var s0 = stdDep.toRelativeFilePath().ToString();
                    var s1 = relFilePath.ToString();
                    if (s0.Equals(s1, StringComparison.InvariantCultureIgnoreCase))
                    {
                        foundStdDep = stdDep;
                        break;
                    }
                }
                set.Add(foundStdDep ?? new SourcePath(relFilePath.ToString(), SourcePath.SourceType.Tools));
            }
            return set;
        }
    }
}
